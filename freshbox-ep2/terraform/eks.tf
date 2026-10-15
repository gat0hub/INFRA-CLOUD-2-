# Learner Lab no permite crear roles IAM: se reutiliza LabRole
data "aws_iam_role" "lab" {
  name = "LabRole"
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = data.aws_iam_role.lab.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.private_app[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true # para usar kubectl desde CloudShell
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
}

# Launch template: EBS cifrado + SG de la capa app + IMDS hop=2
resource "aws_launch_template" "nodes" {
  name_prefix = "${var.project}-nodes-"

  vpc_security_group_ids = [
    aws_security_group.eks_app.id,
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # hop_limit=2 permite que los pods (LB Controller, CloudWatch agent)
  # obtengan credenciales del rol del nodo sin IRSA
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project}-eks-node" }
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project}-ng"
  node_role_arn   = data.aws_iam_role.lab.arn
  subnet_ids      = aws_subnet.private_app[*].id
  instance_types  = [var.node_instance_type]
  ami_type        = "AL2023_ARM_64_STANDARD"

  scaling_config {
    min_size     = var.node_min
    max_size     = var.node_max
    desired_size = var.node_desired
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  update_config {
    max_unavailable = 1
  }

  # Tags para que el Cluster Autoscaler descubra el node group
  tags = {
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
  }

  depends_on = [aws_nat_gateway.nat, aws_route_table_association.private_app]
}

# Addons: metrics-server (necesario para HPA) y Container Insights
resource "aws_eks_addon" "addons" {
  for_each = toset([
    "vpc-cni",
    "kube-proxy",
    "coredns",
    "metrics-server",
    "amazon-cloudwatch-observability",
  ])
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.main]
}
