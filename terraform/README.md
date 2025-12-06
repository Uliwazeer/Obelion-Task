# Obelion Task A - Terraform (Default VPC)
This project prepares Task A resources on AWS (using the **Default VPC**):

Resources created:
- 2 EC2 instances (frontend, backend) using Ubuntu 22.04 AMI (dynamically fetched), 1 vCPU, 1GB RAM, 8GB root disk, public IP
- 1 RDS MySQL 8 instance (private, not publicly accessible) with 20 GB (AWS minimum)
- Security groups: EC2 SG (SSH), RDS SG (MySQL only from EC2 SG)

IMPORTANT:
- This setup uses the **Default VPC** in your AWS account.
- SSH is currently allowed from 0.0.0.0/0 by default in terraform.tfvars.example — **YOU MUST** restrict it to your IP before applying.
- Ensure AWS credentials are configured (env vars or aws configure).
