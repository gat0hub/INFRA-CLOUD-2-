# ALB: 80/443 desde Internet
resource "aws_security_group" "alb" {
  name        = "${var.project}-sg-alb"
  description = "ALB publico"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-sg-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EKS aplicación: solo desde el SG del ALB
resource "aws_security_group" "eks_app" {
  name        = "${var.project}-sg-eks-app"
  description = "Nodos/pods EKS"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-sg-eks-app" }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  for_each                     = toset([for p in var.pod_ports : tostring(p)])
  security_group_id            = aws_security_group.eks_app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.eks_app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS: 3306 solo desde el SG de EKS aplicación
resource "aws_security_group" "rds" {
  name        = "${var.project}-sg-rds"
  description = "RDS MySQL"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-sg-rds" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.eks_app.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}
