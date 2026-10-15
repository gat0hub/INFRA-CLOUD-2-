# FreshBox SpA — Migracion a EKS + RDS Multi-AZ (EP2)

## Descripcion

Migracion de FreshBox desde EC2+Docker (EP1) hacia Amazon EKS (5 pods) y RDS MySQL Multi-AZ. Misma funcionalidad CRUD, plataforma gestionada con orquestacion.

## Arquitectura EP2

| Capa | Componente | Servicio AWS |
|------|-----------|--------------|
| Publica | ALB Ingress | ALB (creado por Ingress Controller) |
| Privada APP | EKS Cluster + Node Group | t4g.small, 2-4 nodos Multi-AZ |
| Privada APP | 5 Deployments x 2 replicas | 10 pods |
| Privada DATA | RDS MySQL Multi-AZ | db.t4g.small, failover automatico |
| Registro | 5 imagenes | ECR |
| Observabilidad | Container Insights | CloudWatch |

## Estructura

```
desarrolloappEP2/
├── README.md
├── init.sql                        (BD freshbox para RDS)
├── microserviciosEKSBackend/
│   ├── get-products/  (Dockerfile, index.js, package.json)
│   ├── create-product/
│   ├── update-product/
│   └── delete-product/
├── microservicioEKSFrontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── index.html
│   ├── css/styles.css
│   └── js/app.js
├── k8s/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── frontend-deployment.yaml
│   ├── get-products-deployment.yaml
│   ├── create-product-deployment.yaml
│   ├── update-product-deployment.yaml
│   ├── delete-product-deployment.yaml
│   ├── ingress.yaml
│   └── hpa.yaml
└── scripts/
    ├── ecr-push.sh
    └── guia-docente-ep2.md
```

## Nota importante

El desarrollo es **autocontenido**: incluye todos los microservicios, frontend, manifiestos K8s y scripts necesarios para implementar sin depender de otra carpeta.

## Variables de Entorno

| Variable | Valor |
|----------|-------|
| DB_HOST | (RDS endpoint) |
| DB_USER | alumno |
| DB_PASS | alumno123 |
| DB_NAME | freshbox |
| DB_PORT | 3306 |

## Prueba local con Docker Desktop

Desde PowerShell, con Docker Desktop iniciado:

```powershell
cd E:\Descargas\freshbox-ep2\app
docker compose up --build -d
docker compose ps
```

Cuando los servicios aparezcan como `healthy` (y `frontend` como `running`), abre
http://localhost:8080. La base de datos se inicializa con `init.sql`; desde la página
puedes crear, editar y eliminar productos. Los datos se conservan en el volumen
`mysql_data`.

Para detener los contenedores sin borrar los datos:

```powershell
docker compose down
```

Para borrar también la base de datos local y sus datos y volver a inicializarla:

```powershell
docker compose down -v
```

Esta configuración es solo para desarrollo local y no reemplaza el despliegue AWS/EKS.

---

2026 - Disenador: Ignacio A. Pastenet M.
