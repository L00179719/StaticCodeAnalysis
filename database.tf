###########################################  RDS Database  ##########################################


# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment_name}-rds-sg"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Allow inbound access on port 3306 for RDS"

  ingress {
    description = "Allow fargate and Bastion to access RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]  # Allow access from any IP address. Adjust as needed.
  }
tags = {
    Name = "${var.environment_name}-database-security-group"
  }

}

resource "aws_db_parameter_group" "my_parameter_group" {
  name        = "${var.environment_name}-db-parameter-group"
  family      = "mysql5.7"
  description = "My custom MySQL parameter group"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "My DB Subnet Group"
  }
}


# RDS MySQL Database

resource "aws_db_instance" "my_db_instance" {
  identifier            = "${var.environment_name}-db-instance"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  db_name               = "mydb"
  username              = "L00179719"
  password              = "mypass"
  parameter_group_name  = aws_db_parameter_group.my_parameter_group.name
  publicly_accessible   = false
  multi_az              = false
  backup_retention_period = 7
  skip_final_snapshot   = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Replace with your security group ID
  db_subnet_group_name = aws_db_subnet_group.default.name

  
}





