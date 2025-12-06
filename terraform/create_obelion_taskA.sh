#!/usr/bin/env bash
set -euo pipefail

# =========================
# Create Terraform project for Obelion Task A (uses Default VPC)
# - Uses Dynamic AMI for Ubuntu 22.04 (Region Agnostic)
# - Writes terraform files into ./obelion-taskA
# - FIX: Uses aws_subnets instead of deprecated aws_subnet_ids
# - FIX: Auto-generates SSH Key Pair to avoid "Key Pair not found" errors
# =========================

PROJECT_DIR="obelion-taskA"
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

# README
cat > README.md <<'README'
# Obelion Task A - Terraform (Default VPC)
This project prepares Task A resources on AWS (using the **Default VPC**):

Resources created:
- **SSH Key Pair**: Auto-generated and saved to `generated_key.pem`
- 2 EC2 instances (frontend, backend) using Ubuntu 22.04 AMI, 1 vCPU, 1GB RAM, 8GB root disk, public IP
- 1 RDS MySQL 8 instance (private) with 20 GB
- Security groups: EC2 SG (SSH), RDS SG (MySQL only from EC2 SG)

IMPORTANT:
- SSH is currently allowed from 0.0.0.0/0 by default in terraform.tfvars.example — **YOU MUST** restrict it to your IP before applying.
- The private key for SSH will be saved locally as `generated_key.pem`.
- **chmod 400 generated_key.pem** before using it.
README

# providers.tf
cat > providers.tf <<'TF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}
TF

# variables.tf
cat > variables.tf <<'TF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type for frontend/backend"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name for the generated AWS Key Pair"
  type        = string
  default     = "obelion-task-key"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to EC2 (your IP). Change from 0.0.0.0/0 for security."
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "ali12345"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  default     = "ali12345"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB (AWS minimum usually 20GB)"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}
TF

# main.tf
cat > main.tf <<'TF'
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

# ---------- SSH Key Generation ----------
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_name
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${path.module}/generated_key.pem"
  content  = tls_private_key.pk.private_key_pem
  file_permission = "0400"
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
  key_name                    = aws_key_pair.kp.key_name

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
  key_name                    = aws_key_pair.kp.key_name

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
  name                    = "obeliondb"
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
TF

# outputs.tf
cat > outputs.tf <<'TF'
output "vpc_id" {
  description = "Default VPC id"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Subnet ids in default VPC"
  value       = data.aws_subnets.default_vpc_subnets.ids
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.mysql.address
}

output "private_key_file" {
  value = local_file.ssh_key.filename
}
TF

# terraform.tfvars.example
cat > terraform.tfvars.example <<'TFVARS'
aws_region = "us-east-2"
instance_type = "t2.micro"
key_name = "obelion-task-key"
# IMPORTANT: set allowed_ssh_cidr to your IP in CIDR notation, e.g. "203.0.113.45/32"
allowed_ssh_cidr = "0.0.0.0/0"
db_username = "ali12345"
db_password = "ali12345"
db_allocated_storage = 20
db_instance_class = "db.t3.micro"
TFVARS

# deploy.sh helper
cat > deploy.sh <<'DEPLOY'
#!/usr/bin/env bash
set -euo pipefail
echo "This will run: terraform init && terraform apply -auto-approve"
if [ ! -f "terraform.tfvars" ]; then
  echo "ERROR: terraform.tfvars not found. Copy terraform.tfvars.example -> terraform.tfvars and edit values before applying."
  exit 1
fi
terraform init
terraform apply -auto-approve
DEPLOY
chmod +x deploy.sh

echo "Done. Project created in ./${PROJECT_DIR}"
echo "1) Edit terraform.tfvars.example -> copy to terraform.tfvars and adjust allowed_ssh_cidr."
echo "2) Ensure AWS credentials are available."
echo "3) Run ./deploy.sh to apply Terraform."
