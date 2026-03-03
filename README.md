# Azure Infrastructure Deployment using Terraform

## 📌 Project Overview

This project provisions production-style Azure infrastructure using Terraform Infrastructure as Code (IaC).

The goal is to automate cloud resource deployment following DevOps and platform engineering best practices.

---

## 🏗 Architecture

Azure resources deployed:

- Resource Group
- Azure Data Lake Storage Acoount
- Azure Data Factory
- Azure SQL Server
- Azure SQL DB with sample database 
- Firewall Policies

Detailed architecture documentation available here:

👉 [View Architecture Diagram & Explanation](https://cloudcraftedraj.github.io/azure-infrastructure-terraform/data_engineer_infra.html)

---

## ⚙️ Technologies Used

- Microsoft Azure
- Terraform
- Azure CLI
- GitHub

## 🚀 Deployment Steps

```bash
az login
az account show
terraform init
terraform plan -var-file=env/dev/dev.auto.tfvars
terraform apply -var-file=env/dev/dev.auto.tfvars
terraform destroy -var-file=env/dev/dev.auto.tfvars