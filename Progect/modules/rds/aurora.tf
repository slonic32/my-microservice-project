# Aurora cluster parameter group
resource "aws_rds_cluster_parameter_group" "aurora" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.name}-aurora-params"
  family      = var.parameter_group_family
  description = "Aurora cluster parameter group for ${var.name}"

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

# Aurora Cluster
resource "aws_rds_cluster" "aurora" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.name}-cluster"
  engine             = local.aurora_engine
  engine_version     = var.engine_version
  engine_mode        = "provisioned"

  database_name   = var.db_name
  master_username = var.username
  master_password = var.password
  port            = local.database_port

  db_subnet_group_name            = aws_db_subnet_group.default.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name

  storage_encrypted       = var.storage_encrypted
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  apply_immediately       = var.apply_immediately

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  copy_tags_to_snapshot = true

  tags = local.common_tags
}

# Aurora writer instance
resource "aws_rds_cluster_instance" "aurora_writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.aurora[0].id

  instance_class = var.instance_class
  engine         = local.aurora_engine
  engine_version = var.engine_version

  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = var.publicly_accessible

  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    {
      Role = "writer"
    }
  )
}

# Aurora reader instances
resource "aws_rds_cluster_instance" "aurora_readers" {
  count = var.use_aurora ? var.aurora_replica_count : 0

  identifier         = "${var.name}-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora[0].id

  instance_class = var.instance_class
  engine         = local.aurora_engine
  engine_version = var.engine_version

  db_subnet_group_name = aws_db_subnet_group.default.name
  publicly_accessible  = var.publicly_accessible

  auto_minor_version_upgrade = true

  promotion_tier = count.index + 1

  tags = merge(
    local.common_tags,
    {
      Role = "reader"
    }
  )
}