#!/usr/bin/env bash
set -euo pipefail

# تحقق من وجود terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
  echo "ERROR: terraform.tfvars not found. Copy terraform.tfvars.example -> terraform.tfvars and edit values before applying."
  exit 1
fi

# تحقق من وجود Key Pair في AWS
key_name=$(grep key_pair_name terraform.tfvars | cut -d '=' -f2 | tr -d ' "')
if ! aws ec2 describe-key-pairs --key-names "$key_name" >/dev/null 2>&1; then
  echo "ERROR: Key pair '$key_name' does not exist in AWS. Please create/import it first."
  exit 1
fi

# خيار لإعادة تدمير الموارد
read -p "Do you want to destroy existing resources first? (yes/no): " confirm
if [ "$confirm" == "yes" ]; then
  echo "Destroying existing resources..."
  terraform destroy -auto-approve
  rm -rf .terraform terraform.tfstate terraform.tfstate.backup
fi

# تشغيل Terraform
echo "Initializing Terraform..."
terraform init

echo "Applying Terraform changes..."
terraform apply -auto-approve

echo "Deployment complete ✅"

