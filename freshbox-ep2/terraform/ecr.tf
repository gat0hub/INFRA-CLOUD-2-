resource "aws_ecr_repository" "repos" {
  for_each             = var.ecr_repositories
  name                 = "${var.project}-${each.value}" # coincide con ecr-push.sh
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
