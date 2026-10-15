# FreshBox SpA - EP2 (EKS + RDS Multi-AZ)

```
freshbox-ep2/
├── terraform/   -> infraestructura (VPC 3 capas, SGs, ECR, RDS Multi-AZ, EKS + addons)
└── app/         -> código del profesor, YA CORREGIDO (nginx.conf, ingress.yaml, hpa-frontend.yaml)
```

Alineado con la **guía de avance EP2** (VPC 10.0.0.0/22, 6 subredes /25, ALB -> frontend:80 y backends:3001-3004, RDS db.t4g.small, HPA 2-5 réplicas al 70%) y con correcciones al código del profesor:
- `app/microservicioEKSFrontend/nginx.conf`: enruta /api/products por método HTTP (GET/POST/PUT/DELETE).
- `app/k8s/ingress.yaml`: el ALB enruta por método HTTP directo a cada backend (condiciones `http-request-method`) y usa el SG del ALB (`<SG_ALB_ID>`).
- `app/k8s/*-deployment.yaml`: añadido `topologySpreadConstraints` (réplicas repartidas entre 2 AZ) y health check `/health` en los Services backend.
- `app/k8s/hpa-frontend.yaml`: HPA que faltaba (ahora los 5 Deployments tienen HPA).
- `app/k8s-alternativo/ingress-via-nginx.yaml`: plan B si el ALB no enruta bien por método (todo entra por el frontend y Nginx reparte). Si lo usas: `kubectl delete -f k8s/ingress.yaml` y aplica este.

> Nota: no probé el Terraform contra AWS. Ejecuta `terraform validate` y `terraform plan` antes del `apply`.

## 1. Infraestructura (CloudShell o PC con credenciales del Learner Lab)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform validate && terraform plan
terraform apply                      # ~20-25 min
aws eks update-kubeconfig --region us-east-1 --name freshbox-cluster
kubectl get nodes
```

## 2. Preparar manifiestos (desde terraform/)
```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
RDS=$(terraform output -raw rds_endpoint)
SGALB=$(terraform output -raw sg_alb)
VPC=$(terraform output -raw vpc_id)
cd ../app
sed -i "s|<ACCOUNT_ID>|$ACCOUNT|g" k8s/*-deployment.yaml
sed -i "s|<RDS_ENDPOINT>|$RDS|g" k8s/configmap.yaml
sed -i "s|<SG_ALB_ID>|$SGALB|g" k8s/ingress.yaml
```

## 3. Imágenes (desde app/). t4g = ARM64, CloudShell es x86 -> emulación
```bash
docker run --privileged --rm tonistiiv/binfmt --install arm64 
bash scripts/ecr-push.sh
```

## 4. Cargar init.sql en RDS (privado -> pod cliente)
```bash
kubectl run mysql-client --rm -i --restart=Never --image=mysql:8.0 -- \
  mysql -h $RDS -u alumno -palumno123 < init.sql
```

## 5. AWS Load Balancer Controller
```bash
helm repo add eks https://aws.github.io/eks-charts && helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=freshbox-cluster --set region=us-east-1 --set vpcId=$VPC
```

## 6. Desplegar
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
kubectl get pods,svc,ingress,hpa -n freshbox
```

## 7. Cluster Autoscaler (escalado del Node Group)
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler -n kube-system \
  --set autoDiscovery.clusterName=freshbox-cluster --set awsRegion=us-east-1
```

## 8. Validar CRUD
```bash
ALB=$(kubectl get ingress -n freshbox freshbox-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$ALB/api/products
curl -X POST http://$ALB/api/products -H 'Content-Type: application/json' -d '{"nombre":"Test","precio":1000,"stock":5}'
curl -X PUT  http://$ALB/api/products/6 -H 'Content-Type: application/json' -d '{"nombre":"Test2","precio":1500,"stock":7}'
curl -X DELETE http://$ALB/api/products/6
```

## 9. Demostrar HPA
```bash
kubectl run load --rm -i --restart=Never --image=busybox -n freshbox -- \
  /bin/sh -c 'while true; do wget -q -O- http://get-products:3001/api/products >/dev/null; done'
kubectl get hpa -n freshbox -w       # en otra terminal
```

## 10. Evidencias sugeridas (nómbralas así, sin mostrar contraseñas)
`01_eks_nodos`, `02_rds_multiaz`, `03_ecr_imagenes`, `04_pods_2az` (`kubectl get pods -n freshbox -o wide`),
`05_ingress_alb`, `06_crud_get/post/put/delete`, `07_hpa_antes`, `08_hpa_bajo_carga`, `09_container_insights`.

## 11. Limpieza (importante, para no gastar el presupuesto del lab)
```bash
kubectl delete ingress freshbox-ingress -n freshbox   # el ALB no está en el estado de Terraform
cd ../terraform && terraform destroy
```
