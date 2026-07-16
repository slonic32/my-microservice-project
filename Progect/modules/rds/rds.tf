# Standard RDS parameter group
resource "aws_db_parameter_group" "standard" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.name}-rds-params"
  family      = var.parameter_group_family
  description = "Standard RDS parameter group for ${var.name}"

  dynamic "parameter" {
    for_each = local.database_parameters

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = local.common_tags
}

# Standard RDS instance
resource "aws_db_instance" "standard" {
  count = var.use_aurora ? 0 : 1

  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = local.database_port

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.standard[0].name

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  apply_immediately       = var.apply_immediately

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  tags = local.common_tags
}