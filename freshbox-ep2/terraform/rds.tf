resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnets"
  subnet_ids = aws_subnet.private_data[*].id
  tags       = { Name = "${var.project}-db-subnets" }
}

resource "aws_db_instance" "mysql" {
  identifier        = "${var.project}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t4g.small"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name != "" ? var.db_name : null
  username = var.db_username
  password = var.db_password

  multi_az               = true # Alta disponibilidad
  storage_encrypted      = true # Cifrado en reposo
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7 # Snapshots automáticos
  backup_window           = "05:00-06:00"
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "${var.project}-mysql" }
}
