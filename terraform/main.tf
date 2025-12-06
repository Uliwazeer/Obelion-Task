# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnet ids for the default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch latest Ubuntu 22.04 AMI dynamically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------- Security Groups ----------
resource "aws_security_group" "ec2_sg" {
  name        = "obelion-ec2-sg"
  description = "Allow SSH inbound from specified CIDR"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "obelion-rds-sg"
  description = "Allow MySQL access from EC2 SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "mysql from ec2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 Instances ----------
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = tolist(data.aws_subnets.default_vpc_subnets.ids)[0]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  root_block_device {
    volume_size = 8
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "obelion-frontend"
  }
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = tolist(data.aws_subnets.default_vpc_subnets.ids)[0]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  root_block_device {
    volume_size = 8
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "obelion-backend"
  }
}

# ---------- RDS Subnet Group ----------
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "obelion-rds-subnet-group"
  subnet_ids = slice(tolist(data.aws_subnets.default_vpc_subnets.ids), 0, 2)
  tags = {
    Name = "obelion-rds-subnet-group"
  }
}

# ---------- RDS Instance (MySQL 8) ----------
resource "aws_db_instance" "mysql" {
  identifier              = "obelion-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = var.db_password
  allocated_storage       = var.db_allocated_storage
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false

  tags = {
    Name = "obelion-mysql"
  }
}

