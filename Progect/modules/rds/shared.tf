locals {
  is_postgresql = var.engine == "postgres"

  database_port = local.is_postgresql ? 5432 : 3306

  aurora_engine = local.is_postgresql ? "aurora-postgresql" : "aurora-mysql"

  default_parameters = local.is_postgresql ? {
    max_connections = "200"
    log_statement   = "ddl"
    work_mem        = "4096"
    } : {
    max_connections = "200"
    slow_query_log  = "1"
    long_query_time = "2"
  }

  database_parameters = merge(
    local.default_parameters,
    var.parameters
  )

  common_tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# Subnet group використовується RDS та Aurora
resource "aws_db_subnet_group" "default" {
  name        = "${var.name}-subnet-group"
  description = "DB subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = local.common_tags
}

# Security group використовується RDS та Aurora
resource "aws_security_group" "rds" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

# Доступ за CIDR
resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.rds.id
  description       = "Database access from ${each.value}"
  from_port         = local.database_port
  to_port           = local.database_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Доступ від інших Security Groups
resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = {
    for index, security_group_id in var.allowed_security_group_ids :
    tostring(index) => security_group_id
  }

  security_group_id            = aws_security_group.rds.id
  description                  = "Database access from security group"
  from_port                    = local.database_port
  to_port                      = local.database_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}