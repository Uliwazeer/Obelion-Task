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

variable "key_pair_name" {
  description = "Existing EC2 Key Pair name to use for SSH (must exist in AWS)"
  type        = string
  default     = "ohio-key"
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
