# 🚀 CI/CD Pipeline with GitHub Actions & Terraform

## Workflow Explanation in 4 Key Points:

1️⃣ Infrastructure (Terraform)
Uses Terraform to create 3 resources on AWS: Backend server (Ubuntu 22.04) for Laravel + Frontend server (Ubuntu 22.04) for Node.js + MySQL RDS database - all in the same VPC and Region with public IPs for servers.

2️⃣ Frontend Pipeline (Docker + Uptime Kuma)
On any Push to main in Frontend repo → GitHub Actions triggers automatically → Builds the application → Connects to server via SSH → Pulls Docker Image from Docker Hub → Runs Uptime Kuma with Docker Compose on Port 3001.

3️⃣ Backend Pipeline (Laravel + Auto Migration)
On any Push to main in Laravel repo → GitHub Actions triggers → Connects to server via SSH → Executes Shell Script that runs git pull to fetch new changes → Automatically runs php artisan migrate to apply Database Schema changes.

4️⃣ Monitoring & Alerts (CPU > 50%)
Each server has a Cron Job running every 5 minutes → Checks CPU utilization → If exceeds 50% → Automatically sends Email to Admin with server details, running processes, and recommended Actions for resolution.
In short: Terraform builds infrastructure → GitHub Actions deploys applications automatically → Monitoring watches performance and sends alerts - everything is automated! 🚀


![unnamed](https://github.com/user-attachments/assets/0effbe7e-c2d8-4051-a367-6febadc50c88)
##Video Live Demo 
https://drive.google.com/file/d/17HMRNYy1Sk1Fk9zY0cQoG7FUFHZ7yoEn/view?usp=sharing

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Task Group A: Infrastructure Setup (Terraform)](#task-group-a-infrastructure-setup-terraform)
- [Task Group B: CI/CD Pipelines](#task-group-b-cicd-pipelines)
- [Monitoring & Alerts](#monitoring--alerts)
- [Installation Guide](#installation-guide)
- [Deployment Scenarios](#deployment-scenarios)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## 🎯 Project Overview

This project implements a complete CI/CD pipeline for two applications:
- **Frontend Application**: Uptime Kuma (monitoring tool) deployed via Docker Compose
- **Backend Application**: Node.js application managed with PM2

The infrastructure is provisioned using Terraform and deployments are automated using GitHub Actions with SSH-based deployment to Ubuntu 22.04 servers.

### 🔗 Live Repositories
- **Frontend Repo**: [https://github.com/Uliwazeer/uptime-kuma](https://github.com/Uliwazeer/uptime-kuma)
- **Backend Repo**: [Your Backend Repository URL]
- **Terraform Repo**: Located in `Task-Obelion/obelion-taskA/`

### 🌐 Server Information
- **Backend Server IP**: `18.221.228.203` (Node.js + PM2)
- **Frontend Server IP**: `18.221.36.156` (Docker + Uptime Kuma)
- **SSH Key**: `ohio-key.pem`

> **Note**: The IPs might seem reversed from typical convention - Backend is on .203 and Frontend is on .156

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          TERRAFORM INFRASTRUCTURE                         │
│                      (Task-Obelion/obelion-taskA/)                       │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  main.tf │ variables.tf │ outputs.tf │ providers.tf │ tfvars    │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└────────────────────────┬──────────────────────────┬────────────────────┘
                         │                          │
                         ▼                          ▼
      ┌──────────────────────────┐    ┌──────────────────────────┐
      │   Backend Server         │    │   Frontend Server        │
      │   18.221.228.203         │    │   18.221.36.156         │
      │   Ubuntu 22.04 LTS       │    │   Ubuntu 22.04 LTS      │
      └──────────────────────────┘    └──────────────────────────┘
                ▲                                    ▲
                │                                    │
                │ SSH Deploy                         │ SSH Deploy
                │ (ohio-key.pem)                     │ (ohio-key.pem)
                │                                    │
      ┌──────────────────────────┐    ┌──────────────────────────┐
      │  GitHub Actions          │    │  GitHub Actions          │
      │  Backend Deploy          │    │  Frontend Deploy         │
      │  (Push to master)        │    │  (Push to master)        │
      └──────────────────────────┘    └──────────────────────────┘
                ▲                                    ▲
                │                                    │
                │                                    │
      ┌──────────────────────────┐    ┌──────────────────────────┐
      │  Backend Repo            │    │  Frontend Repo           │
      │  (mysql App)             │    │  github.com/Uliwazeer/   │
      │                          │    │  uptime-kuma             │
      └──────────────────────────┘    └──────────────────────────┘

BACKEND SERVER (18.221.228.203):        FRONTEND SERVER (18.221.36.156):
├── Node.js v20.x                       ├── Docker Engine
├── NPM                                 ├── Docker Compose v2.24.0
├── PM2 (Process Manager)               ├── Uptime Kuma Container
├── Application: ~/backend              ├── Application: ~/frontend
└── Auto-restart on failure             └── Port: 3001

           │                                       │
           └───────────┬───────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ CPU Monitoring  │
              │ Email Alerts    │
              │ Cron: */5 min   │
              │ Threshold: >50% │
              └─────────────────┘
```

---

## 📁 Repository Structure

### Terraform Repository Structure
```
Task-Obelion/obelion-taskA/
├── 📄 main.tf                      # Main infrastructure configuration
├── 📄 variables.tf                 # Variable definitions
├── 📄 outputs.tf                   # Output values (IPs, etc.)
├── 📄 providers.tf                 # AWS provider configuration
├── 📄 terraform.tfvars             # Variable values (DO NOT COMMIT)
├── 📄 terraform.tfvars.example     # Example variable file
├── 📄 terraform.tfstate            # State file (DO NOT COMMIT)
├── 📄 terraform.tfstate.backup     # State backup
├── 🔑 ohio-key.pem                 # SSH private key (DO NOT COMMIT)
├── 📄 create_obelion_taskA.sh      # Infrastructure creation script
├── 📄 deploy.sh                    # Deployment automation script
├── 📄 README.md                    # This documentation
└── 📁 uptime-kuma/                 # Frontend application files
    └── docker-compose/
        └── docker-compose.yml
```

### Frontend Repository Structure
```
uptime-kuma/
├── .github/
│   └── workflows/
│       └── frontend-deploy.yml              # Frontend CI/CD pipeline
├── docker-compose/
│   └── docker-compose.yml          # Docker Compose configuration
├── src/                            # Application source code
├── package.json
└── README.md
```

### Backend Repository Structure
```
backend/
├── .github/
│   └── workflows/
│       └── backend-deploy.yml              # Backend CI/CD pipeline
├── src/                            # Application source code
├── ecosystem.config.js             # PM2 configuration
├── package.json
└── README.md
```

---

## ✅ Prerequisites

### Required Tools & Accounts
1. **GitHub Account** with repository access
2. **Terraform** (v1.0+) - Infrastructure as Code
3. **AWS Account** with appropriate permissions
4. **SSH Key** (`ohio-key.pem`) - Already generated
5. **Email Service** (for alerts) ali.wazeer2000@gmail.com - alinourwazeer@gmail.com

### Server Requirements
- **OS**: Ubuntu 22.04 LTS
- **RAM**: Minimum 1GB
- **CPU**: 1 cores recommended
- **Storage**: 8GB minimum
- **Network**: Public IPs with security group rules

### Local Development Tools
```bash
# Terraform
terraform --version

# AWS CLI (optional but recommended)
aws --version

# GitHub CLI (optional)
gh --version

# SSH client
ssh -V
```

---

## 🚀 Task Group A: Infrastructure Setup (Terraform)

### Step 1: Terraform File Descriptions

#### 1. **main.tf**
Defines the core infrastructure resources:
```hcl
# Example structure (customize based on your actual main.tf)
provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "backend_server" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = "Backend-Server"
    Environment = "Production"
  }

  # Private IP: Will get public IP 18.221.228.203
}

resource "aws_instance" "frontend_server" {
  ami           = var.ubuntu_ami
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = "Frontend-Server"
    Environment = "Production"
  }

  # Private IP: Will get public IP 18.221.36.156
}

resource "aws_security_group" "allow_traffic" {
  name        = "obelion-security-group"
  description = "Allow SSH, HTTP, and application ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Uptime Kuma"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

#### 2. **variables.tf**
Defines input variables:
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "ubuntu_ami" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "ohio-key"
}
```

#### 3. **outputs.tf**
Defines output values:
```hcl
output "backend_server_ip" {
  description = "Backend server public IP"
  value       = aws_instance.backend_server.public_ip
}

output "frontend_server_ip" {
  description = "Frontend server public IP"
  value       = aws_instance.frontend_server.public_ip
}

output "ssh_command_backend" {
  description = "SSH command for backend server"
  value       = "ssh -i ohio-key.pem ubuntu@${aws_instance.backend_server.public_ip}"
}

output "ssh_command_frontend" {
  description = "SSH command for frontend server"
  value       = "ssh -i ohio-key.pem ubuntu@${aws_instance.frontend_server.public_ip}"
}
```

#### 4. **providers.tf**
Configures cloud providers:
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

#### 5. **terraform.tfvars** (Keep secure - DO NOT COMMIT)
```hcl
aws_region    = "us-east-2"
ubuntu_ami    = "ami-xxxxxxxxxxxxx"  # Ubuntu 22.04 for us-east-2
instance_type = "t2.micro"
key_name      = "ohio-key"
```

#### 6. **terraform.tfvars.example** (Safe to commit)
```hcl
# Copy this file to terraform.tfvars and fill in your values
aws_region    = "us-east-2"
ubuntu_ami    = "ami-xxxxxxxxxxxxx"
instance_type = "t2.micro"
key_name      = "ohio-key"
```

### Step 2: Deploy Infrastructure

#### Using Automated Script
```bash
# Navigate to terraform directory
cd ~/Task-Obelion/obelion-taskA/

# Run the creation script
bash create_obelion_taskA.sh

# This script will:
# 1. Initialize Terraform
# 2. Validate configuration
# 3. Plan infrastructure
# 4. Apply changes
# 5. Output server IPs
```

#### Manual Deployment
```bash
# Navigate to terraform directory
cd ~/Task-Obelion/obelion-taskA/

# Initialize Terraform (download providers)
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan changes (preview)
terraform plan

# Apply changes (create infrastructure)
terraform apply

# Review outputs
terraform output

# Save outputs to files
terraform output backend_server_ip > backend_ip.txt
terraform output frontend_server_ip > frontend_ip.txt
```

### Step 3: Verify Infrastructure

```bash
# Check Terraform state
terraform show

# List all resources
terraform state list

# Get specific resource details
terraform state show aws_instance.backend_server
terraform state show aws_instance.frontend_server

# Test SSH connections
ssh -i ohio-key.pem ubuntu@18.221.228.203 "echo 'Backend server connected'"
ssh -i ohio-key.pem ubuntu@18.221.36.156 "echo 'Frontend server connected'"
```

### Step 4: Infrastructure Management Commands

```bash
# Refresh state
terraform refresh

# Update infrastructure
terraform apply

# Destroy specific resource
terraform destroy -target=aws_instance.backend_server

# Destroy all infrastructure
terraform destroy

# Import existing resource
terraform import aws_instance.backend_server i-xxxxxxxxxxxxx

# View execution plan in detail
terraform plan -out=tfplan
terraform show tfplan
```

---

## 🔄 Task Group B: CI/CD Pipelines

### Frontend Pipeline (Uptime Kuma)

#### Repository Information
- **GitHub Repo**: [https://github.com/Uliwazeer/uptime-kuma](https://github.com/Uliwazeer/uptime-kuma)
- **Server IP**: `18.221.36.156`
- **Port**: `3001`
- **Access URL**: `http://18.221.36.156:3001`
- **Technology**: Docker + Docker Compose

#### GitHub Actions Workflow (`.github/workflows/frontend-deploy.yml`)

```yaml
name: Frontend Deploy

on:
  push:
    branches:
      - master

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      # Step 1: Checkout the repository
      - name: Checkout repository
        uses: actions/checkout@v3

      # Step 2: Setup SSH key from GitHub Secrets
      - name: Setup SSH key
        uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.FRONTEND_SSH_KEY }}

      # Step 3: Install Docker & Docker Compose
      - name: Install Docker & Docker Compose
        run: |
          echo "📦 Installing Docker..."
          curl -fsSL https://get.docker.com -o get-docker.sh
          sudo sh get-docker.sh
          sudo usermod -aG docker $USER
          
          echo "📦 Installing Docker Compose..."
          sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
          sudo chmod +x /usr/local/bin/docker-compose
          
          echo "✅ Verifying installations..."
          docker --version
          docker-compose --version

      # Step 4: Build Frontend using docker-compose
      - name: Build Frontend
        run: |
          echo "🔨 Building Frontend..."
          docker-compose -f docker-compose/docker-compose.yml build

      # Step 5: Deploy to EC2 server
      - name: Deploy to server (18.221.36.156)
        run: |
          ssh -o StrictHostKeyChecking=no ubuntu@18.221.36.156 "
            echo '📁 Setting up frontend directory...'
            mkdir -p ~/frontend &&
            cd ~/frontend &&
            
            echo '🔄 Cloning/Updating repository...'
            git clone https://github.com/Uliwazeer/uptime-kuma.git . || git pull &&
            
            echo '📥 Pulling Docker images...'
            docker-compose -f docker-compose/docker-compose.yml pull &&
            
            echo '🚀 Starting containers...'
            docker-compose -f docker-compose/docker-compose.yml up -d &&
            
            echo '✅ Deployment completed!'
            docker-compose -f docker-compose/docker-compose.yml ps
          "
```

#### Docker Compose Configuration

File: `docker-compose/docker-compose.yml`
```yaml
version: '3.8'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: always
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma-data:/app/data
    environment:
      - TZ=Africa/Cairo
      - NODE_ENV=production
    networks:
      - uptime-network

volumes:
  uptime-kuma-data:
    driver: local

networks:
  uptime-network:
    driver: bridge
```

#### Configure GitHub Secrets for Frontend

Navigate to: **Repository → Settings → Secrets and Variables → Actions**

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `FRONTEND_SSH_KEY` | `[Contents of ohio-key.pem]` | Private SSH key for deployment |

**How to add the secret**:
```bash
# Display key content
cat ~/Task-Obelion/obelion-taskA/ohio-key.pem

# Copy output including:
# -----BEGIN RSA PRIVATE KEY-----
# [key content]
# -----END RSA PRIVATE KEY-----

# Then paste into GitHub Secrets
```

---

### Backend Pipeline (Node.js + PM2)

#### Repository Information
- **GitHub Repo**: [Your Backend Repository URL]
- **Server IP**: `18.221.228.203`
- **Port**: `8000`
- **Access URL**: `http://18.221.228.203:8000`
- **Technology**: Node.js + PM2

#### GitHub Actions Workflow (`.github/workflows/backend-deploy.yml`)

```yaml
name: Backend Deploy

on:
  push:
    branches:
      - master

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      # Step 1: Checkout repository
      - name: Checkout repository
        uses: actions/checkout@v3
      
      # Step 2: Setup SSH key
      - name: Setup SSH key
        uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.BACKEND_SSH_KEY }}
      
      # Step 3: Setup Node.js & PM2 on Server
      - name: Setup Node.js & PM2 on Server
        run: |
          ssh -o StrictHostKeyChecking=no ubuntu@18.221.228.203 << 'EOF'
            echo "📥 Installing Node.js v20.x..."
            if ! command -v node > /dev/null; then
              curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
              sudo apt-get install -y nodejs
            fi
            
            echo "📦 Installing PM2 globally..."
            if ! command -v pm2 > /dev/null; then
              sudo npm install -g pm2
            fi
            
            echo "🔧 Setting up PM2 startup..."
            pm2 startup systemd -u ubuntu --hp /home/ubuntu || true
            
            echo "✅ Verifying installation..."
            node --version
            npm --version
            pm2 --version
          EOF
      
      # Step 4: Deploy to EC2 Backend
      - name: Deploy to EC2 Backend (18.221.228.203)
        run: |
          ssh -o StrictHostKeyChecking=no ubuntu@18.221.228.203 << 'EOF'
            echo "📁 Navigating to backend directory..."
            cd ~/backend
            
            echo "🔄 Pulling latest changes..."
            git reset --hard
            git pull origin master
            
            echo "📦 Installing dependencies..."
            npm install --production
            
            echo "🔨 Building the project..."
            if grep -q '"build"' package.json; then
              npm run build
            else
              echo "⚠️  No build script found, skipping build step."
            fi
            
            echo "🚀 Restarting application with PM2..."
            if [ -f ecosystem.config.js ]; then
              pm2 restart ecosystem.config.js --update-env || pm2 start ecosystem.config.js
            elif pm2 list | grep -q "uptime-kuma"; then
              pm2 restart uptime-kuma
            else
              echo "Starting new PM2 process..."
              pm2 start ecosystem.config.js
            fi
            
            echo "💾 Saving PM2 process list..."
            pm2 save
            
            echo "✅ Deployment completed successfully!"
            pm2 status
          EOF
```

#### PM2 Configuration

File: `ecosystem.config.js`
```javascript
module.exports = {
  apps: [{
    name: 'backend-app',
    script: './src/index.js',
    instances: 1,
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 8000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true
  }]
};
```

#### Configure GitHub Secrets for Backend

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `BACKEND_SSH_KEY` | `[Contents of ohio-key.pem]` | Same SSH key for backend deployment |

---

## 📊 Monitoring & Alerts

### CPU Utilization Alert (Threshold: >50%)

#### Install Required Packages (On Both Servers)

```bash
# SSH into Backend Server
ssh -i ohio-key.pem ubuntu@18.221.228.203

# Install monitoring tools
sudo apt update
sudo apt install -y sysstat bc mailutils postfix

# Configure Postfix
sudo dpkg-reconfigure postfix
# Select: Internet Site
# Enter: your-domain.com or server hostname
```

```bash
# SSH into Frontend Server
ssh -i ohio-key.pem ubuntu@18.221.36.156

# Same installation steps
sudo apt update
sudo apt install -y sysstat bc mailutils postfix
sudo dpkg-reconfigure postfix
```

#### Create Monitoring Script

**For Backend Server (18.221.228.203)**:

File: `/home/ubuntu/cpu_alert.sh`
```bash
#!/bin/bash

# Configuration
THRESHOLD=50
EMAIL="admin@example.com"
HOSTNAME=$(hostname)
SERVER_IP="18.221.228.203"
SERVER_TYPE="Backend (Node.js + PM2)"

# Get CPU utilization
CPU=$(mpstat 1 1 | awk '/Average/ {print 100 - $12}' | cut -d'.' -f1)

# Check if CPU exceeds threshold
if [ "$CPU" -gt "$THRESHOLD" ]; then
    SUBJECT="⚠️ CPU Alert: $SERVER_TYPE - $HOSTNAME"
    BODY="CPU utilization on $HOSTNAME ($SERVER_IP) is above ${THRESHOLD}%

Server Type: $SERVER_TYPE
Current CPU Usage: ${CPU}%
Time: $(date)
Threshold: ${THRESHOLD}%

Please investigate the issue immediately.

Server Details:
- Hostname: $HOSTNAME
- IP Address: $SERVER_IP
- Type: Backend Server
- Technology: Node.js + PM2
- Uptime: $(uptime)

Running Processes:
$(pm2 status)

Top CPU Consumers:
$(ps aux --sort=-%cpu | head -10)

Recommended Actions:
1. Check PM2 logs: pm2 logs
2. Check system logs: journalctl -xe
3. Monitor in real-time: htop
4. Restart if needed: pm2 restart all
"
    
    echo "$BODY" | mail -s "$SUBJECT" "$EMAIL"
    echo "$(date): Alert sent - CPU at ${CPU}% on $SERVER_IP" >> /var/log/cpu_alerts.log
fi
```

**For Frontend Server (18.221.36.156)**:

File: `/home/ubuntu/cpu_alert.sh`
```bash
#!/bin/bash

# Configuration
THRESHOLD=50
EMAIL="admin@example.com"
HOSTNAME=$(hostname)
SERVER_IP="18.221.36.156"
SERVER_TYPE="Frontend (Docker + Uptime Kuma)"

# Get CPU utilization
CPU=$(mpstat 1 1 | awk '/Average/ {print 100 - $12}' | cut -d'.' -f1)

# Check if CPU exceeds threshold
if [ "$CPU" -gt "$THRESHOLD" ]; then
    SUBJECT="⚠️ CPU Alert: $SERVER_TYPE - $HOSTNAME"
    BODY="CPU utilization on $HOSTNAME ($SERVER_IP) is above ${THRESHOLD}%

Server Type: $SERVER_TYPE
Current CPU Usage: ${CPU}%
Time: $(date)
Threshold: ${THRESHOLD}%

Please investigate the issue immediately.

Server Details:
- Hostname: $HOSTNAME
- IP Address: $SERVER_IP
- Type: Frontend Server
- Technology: Docker + Uptime Kuma
- Uptime: $(uptime)

Docker Status:
$(docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.CPUPerc}}\t{{.MemPerc}}')

Docker Stats:
$(docker stats --no-stream)

Top CPU Consumers:
$(ps aux --sort=-%cpu | head -10)

Recommended Actions:
1. Check container logs: docker-compose logs
2. Check system logs: journalctl -xe
3. Monitor in real-time: htop
4. Restart containers: docker-compose restart
"
    
    echo "$BODY" | mail -s "$SUBJECT" "$EMAIL"
    echo "$(date): Alert sent - CPU at ${CPU}% on $SERVER_IP" >> /var/log/cpu_alerts.log
fi
```

#### Make Scripts Executable

```bash
# On Backend Server
chmod +x /home/ubuntu/cpu_alert.sh

# On Frontend Server
chmod +x /home/ubuntu/cpu_alert.sh
```

#### Setup Cron Jobs

```bash
# On both servers
crontab -e

# Add this line to check every 5 minutes
*/5 * * * * /home/ubuntu/cpu_alert.sh
```

#### Verify Cron Setup

```bash
# List cron jobs
crontab -l

# Check cron service
sudo systemctl status cron

# Test the script manually
bash /home/ubuntu/cpu_alert.sh

# Check alert logs
tail -f /var/log/cpu_alerts.log
```

#### Test Email Alerts

```bash
# Test email system
echo "Test email from $(hostname)" | mail -s "Test Alert" admin@example.com

# Check mail logs
tail -f /var/log/mail.log

# Verify postfix status
sudo systemctl status postfix
```

---

## 📖 Installation Guide

### Complete Setup (Step-by-Step)

#### 1. Prepare SSH Key Permissions

```bash
# Set proper permissions for ohio-key.pem
cd ~/Task-Obelion/obelion-taskA/
chmod 400 ohio-key.pem

# Verify permissions
ls -la ohio-key.pem
# Should show: -r-------- 1 user user ... ohio-key.pem

# Test connections
ssh -i ohio-key.pem ubuntu@18.221.228.203 "echo 'Backend server: Connected ✅'"
ssh -i ohio-key.pem ubuntu@18.221.36.156 "echo 'Frontend server: Connected ✅'"
```

#### 2. Setup Backend Server (18.221.228.203)

```bash
# SSH into Backend server
ssh -i ohio-key.pem ubuntu@18.221.228.203

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js v20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
node --version  # Should show v20.x.x
npm --version

# Install PM2 globally
sudo npm install -g pm2

# Verify PM2 installation
pm2 --version

# Setup PM2 startup script
pm2 startup systemd -u ubuntu --hp /home/ubuntu
# Run the command it outputs

# Clone your backend repository
cd ~
git clone https://github.com/Uliwazeer/backend-app.git backend
cd backend

# Install dependencies
npm install

# Create PM2 ecosystem file
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'backend-app',
    script: './src/index.js',
    instances: 1,
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 8000
    }
  }]
};
EOF

# Start application with PM2
pm2 start ecosystem.config.js

# Save PM2 process list
pm2 save

# Check status
pm2 status
pm2 logs

# Test application
curl http://localhost:8000
# Or from external: curl http://18.221.228.203:8000
```

#### 3. Setup Frontend Server (18.221.36.156)

```bash
# SSH into Frontend server
ssh -i ohio-key.pem ubuntu@18.221.36.156

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker ubuntu

# Logout and login again for group changes
exit
ssh -i ohio-key.pem ubuntu@18.221.36.156

# Verify Docker installation
docker --version
docker run hello-world

# Install Docker Compose v2.24.0
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version

# Create frontend directory
mkdir -p ~/frontend
cd ~/frontend

# Clone Uptime Kuma repository
git clone https://github.com/Uliwazeer/uptime-kuma.git .

# Create docker-compose directory if not exists
mkdir -p docker-compose

# Create Docker Compose file
cat > docker-compose/docker-compose.yml << 'EOF'
version: '3.8'

services:
```

## Create DB MYSQL By AWS RDS
<img width="1366" height="704" alt="Screenshot (769)" src="https://github.com/user-attachments/assets/8f63955f-210c-4cb6-bd25-2bd38e028ce7" />


## Create Key
<img width="1366" height="664" alt="Screenshot (770)" src="https://github.com/user-attachments/assets/88a07124-8e6c-4665-92f4-18554e15a30e" />


## Create 2 EC2
<img width="1366" height="704" alt="Screenshot (771)" src="https://github.com/user-attachments/assets/6599db52-1fae-4d74-bab3-b3e1180e06de" />


## Frontend Deploy on frontend EC2
<img width="1366" height="683" alt="Screenshot (772)" src="https://github.com/user-attachments/assets/5c5fb2a0-93a1-41d9-bc10-0e70f4fceb07" />

## Login Page App

<img width="1366" height="693" alt="Screenshot (773)" src="https://github.com/user-attachments/assets/cdfbdb66-9271-417d-aefa-357d0b42263e" />

<img width="1366" height="685" alt="Screenshot (792)" src="https://github.com/user-attachments/assets/ef2c064e-b5c6-467f-a312-7ceb0a1b82f2" />
<img width="1366" height="683" alt="Screenshot (793)" src="https://github.com/user-attachments/assets/db795e82-b12c-4b0b-b71f-b9760b18a6e2" />


## EC2 Backend 
<img width="1366" height="708" alt="Screenshot (775)" src="https://github.com/user-attachments/assets/e9530fd1-e1fd-4524-84ec-91f5bb932103" />

## PM2
<img width="1366" height="700" alt="Screenshot (777)" src="https://github.com/user-attachments/assets/c0f956ef-571f-432c-8863-755308e0bc6c" />
<img width="1366" height="713" alt="Screenshot (778)" src="https://github.com/user-attachments/assets/07114433-ef7b-43bc-9780-e1009899c938" />
<img width="1366" height="708" alt="Screenshot (779)" src="https://github.com/user-attachments/assets/4e501a49-0bce-4023-a647-202a0b1da69f" />

## Run Backend
<img width="1366" height="704" alt="Screenshot (780)" src="https://github.com/user-attachments/assets/944af859-5e5e-447a-ab01-28b474c31db4" />

## Alarm
<img width="1366" height="649" alt="Screenshot (788)" src="https://github.com/user-attachments/assets/c2cab44a-207f-42dc-a008-919bec48908f" />

## Run Frontend
<img width="1366" height="700" alt="Screenshot (781)" src="https://github.com/user-attachments/assets/6485149b-d8e6-422c-815d-26755289a010" />


## Backend Deploy
<img width="1366" height="669" alt="Screenshot (795)" src="https://github.com/user-attachments/assets/97ec546f-04e1-44b9-83a5-2bce6734105c" />


## Frontend Deploy
<img width="1366" height="689" alt="Screenshot (796)" src="https://github.com/user-attachments/assets/fe91ed78-dc93-4fa0-9ef3-412580b6fecf" />

## Alarm Graph
<img width="1366" height="668" alt="Screenshot (799)" src="https://github.com/user-attachments/assets/7207f574-cf4f-4395-b57d-6b8020bca375" />

## Stress On Frontend EC2
<img width="1366" height="704" alt="Screenshot (801)" src="https://github.com/user-attachments/assets/f6bae291-d1f3-4e0f-9e91-dfecdb33b769" />

## Stress On Backend EC2
<img width="1366" height="713" alt="Screenshot (802)" src="https://github.com/user-attachments/assets/e55b7c04-ee74-4b0b-bd2c-017853ab69bc" />

## Monitor Frontend EC2
<img width="1366" height="683" alt="Screenshot (807)" src="https://github.com/user-attachments/assets/506899af-d892-44a4-9221-25e22153bd97" />

## Alarm On Gmail
<img width="1366" height="672" alt="Screenshot (808)" src="https://github.com/user-attachments/assets/d5a1cb2d-bf66-4918-bc47-b46e4fe59cf8" />

<img width="1366" height="713" alt="Screenshot (809)" src="https://github.com/user-attachments/assets/11625ff5-812d-455f-a5ae-5b3ad1ef5089" />

## DB SQL RDS
<img width="1366" height="660" alt="Screenshot (811)" src="https://github.com/user-attachments/assets/71b34c1b-2b52-4d92-96d0-6bc48973db27" />

## SNS Gmail
<img width="1366" height="645" alt="Screenshot (813)" src="https://github.com/user-attachments/assets/1470c4a6-f765-4deb-9767-dcdeffbcad4e" />

## CloudWatch
<img width="1366" height="653" alt="Screenshot (814)" src="https://github.com/user-attachments/assets/97726392-29df-4341-a8cb-40195c73383e" />

## Frontend and Backend EC2 Graph
<img width="1366" height="640" alt="Screenshot (815)" src="https://github.com/user-attachments/assets/6b039b5c-98c1-4d40-9272-8bebc5d69139" />

## Secuity Group
<img width="1366" height="656" alt="Screenshot (820)" src="https://github.com/user-attachments/assets/ed0fa023-aa7c-47ea-b077-cd2c0af82289" />

## CloudWatch Agent
<img width="1366" height="713" alt="Screenshot (830)" src="https://github.com/user-attachments/assets/1db50f41-a265-40c8-a6c4-895d940cd7aa" />
<img width="1366" height="713" alt="Screenshot (829)" src="https://github.com/user-attachments/assets/5214441c-97c8-4475-9ec9-da47e60e0b86" />
<img width="1366" height="721" alt="Screenshot (832)" src="https://github.com/user-attachments/assets/49631055-cbb2-4d6c-95d1-8b4ef89f4354" />

## Finally Running App

<img width="1366" height="685" alt="Screenshot (792)" src="https://github.com/user-attachments/assets/07383db8-fdbe-4d96-abdc-10b0d3a0b910" />
<img width="1366" height="668" alt="Screenshot (790)" src="https://github.com/user-attachments/assets/cd24ae3f-56a0-41d6-be14-4573ec2fa153" />
<img width="1366" height="683" alt="Screenshot (793)" src="https://github.com/user-attachments/assets/024dd56e-31c8-4326-96a8-baa510ea870f" />

## Destroy Resources
<img width="1366" height="717" alt="Screenshot (821)" src="https://github.com/user-attachments/assets/d7d247ec-b6ef-4446-b45e-e19c43337731" />








