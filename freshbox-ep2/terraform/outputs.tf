output "vpc_id" { value = aws_vpc.main.id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "private_app_subnets" { value = aws_subnet.private_app[*].id }
output "private_data_subnets" { value = aws_subnet.private_data[*].id }
output "sg_alb" { value = aws_security_group.alb.id }
output "sg_eks_app" { value = aws_security_group.eks_app.id }
output "sg_rds" { value = aws_security_group.rds.id }
output "cluster_name" { value = aws_eks_cluster.this.name }
output "rds_endpoint" { value = aws_db_instance.mysql.address }
output "ecr_urls" { value = { for k, v in aws_ecr_repository.repos : k => v.repository_url } }
output "kubeconfig_cmd" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}"
}
