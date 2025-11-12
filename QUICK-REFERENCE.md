# Quick Reference Guide

## What Just Happened?

We fixed your Terraform setup to work with your AWS account limitations by making the ALB and Key Pair modules **optional**.

---

## Current Status ✅

### What Will Deploy
- VPC with 6 subnets (private & public)
- NAT Gateways (for private subnet internet access)
- Internet Gateway
- Security Groups (ALB, EC2, RDS)
- RDS Database

### What Won't Deploy (No Errors!)
- Application Load Balancer (AWS account limitation)
- EC2 Key Pair (key file not available)
- Auto Scaling Group (depends on ALB)
- CloudFront (no domain)
- Route53 (no domain)

---

## Files Changed

| File | Change | Why |
|------|--------|-----|
| `root/variables.tf` | Added 2 variables | To control optional features |
| `root/main.tf` | Added `count = var.deploy_alb ? 1 : 0` | Make ALB optional |
| `root/main.tf` | Added `count = var.deploy_key_pair ? 1 : 0` | Make key pair optional |
| `root/main.tf` | Updated ASG/CloudFront references | Handle optional modules |
| `root/terraform.tfvars` | Added deploy flags | Set to false by default |

---

## Files Created

| File | Purpose |
|------|---------|
| `README-ISSUE.md` | Detailed explanation of all 5 errors and solutions |
| `DEPLOYMENT-GUIDE.md` | Step-by-step deployment instructions |
| `SOLUTIONS-SUMMARY.md` | Summary of all changes made |
| `QUICK-REFERENCE.md` | This file |

---

## Deploy Now (3 Simple Steps)

### Step 1: Initialize
```bash
cd root/
terraform init
```

### Step 2: Check
```bash
terraform plan
```

### Step 3: Deploy
```bash
terraform apply
```

Expected time: 5-10 minutes

---

## Enable Features Later

### To Add ALB (when AWS supports it)
```hcl
# In terraform.tfvars, change:
deploy_alb = true

# Then:
terraform apply
```

### To Add Key Pair (when you have SSH key)
```bash
# Generate key:
ssh-keygen -t rsa -b 4096 -f modules/key/client_key -N ""

# In terraform.tfvars, change:
deploy_key_pair = true

# Then:
terraform apply
```

### To Add CloudFront & Route53 (when you have domain)
```hcl
# In terraform.tfvars, change:
certificate_domain_name = "yourdomain.com"
additional_domain_name = "subdomain.yourdomain.com"

# Then:
terraform apply
```

---

## Common Commands

```bash
# Validate syntax
terraform validate

# See what will change
terraform plan

# Create/update resources
terraform apply

# Destroy everything (CAREFUL!)
terraform destroy

# Just destroy ALB when re-enabling
terraform destroy -target module.alb

# Show current state
terraform show

# Get specific output
terraform output vpc_id
```

---

## Settings Explained

### terraform.tfvars
```hcl
# AWS Settings
region = "ap-southeast-1"              # AWS region
project_name = "10weeksofcloudops-demo" # Name prefix

# Network
vpc_cidr = "10.0.0.0/16"               # VPC network
pub_sub_1a_cidr = "10.0.1.0/24"       # Public subnet 1
pub_sub_2b_cidr = "10.0.2.0/24"       # Public subnet 2
pri_sub_3a_cidr = "10.0.3.0/24"       # Private subnet 1
pri_sub_4b_cidr = "10.0.4.0/24"       # Private subnet 2
pri_sub_5a_cidr = "10.0.5.0/24"       # Private subnet 3 (RDS)
pri_sub_6b_cidr = "10.0.6.0/24"       # Private subnet 4 (RDS)

# Database
db_username = "admin"                  # RDS username
db_password = "admin"                  # RDS password

# Optional Features
certificate_domain_name = ""           # For CloudFront (empty = skip)
additional_domain_name = ""            # For Route53 (empty = skip)
deploy_alb = false                     # ALB on/off (limited by AWS account)
deploy_key_pair = false                # Key pair on/off
```

---

## Troubleshooting

### Error: "This AWS account does not support creating load balancers"
✅ Already fixed! `deploy_alb = false`

### Error: "Key is not in valid OpenSSH public key format"
✅ Already fixed! `deploy_key_pair = false`

### Error: "invalid CIDR address"
✅ Already fixed! Added all CIDR values to terraform.tfvars

### Error: "Missing resource instance key"
✅ Already fixed! Uncommented ACM certificate data source

### Error: "Duplicate data configuration"
✅ Already fixed! Removed duplicate from main.tf

### Plan shows "0 to add"
✅ This means everything is already created. If you need to change something, update terraform.tfvars and run `terraform apply` again.

---

## What Each Component Does

| Component | Purpose | Status |
|-----------|---------|--------|
| **VPC** | Virtual network | ✅ Always created |
| **Subnets** | Network segments | ✅ Always created |
| **NAT Gateway** | Allows private→internet | ✅ Always created |
| **Security Groups** | Firewall rules | ✅ Always created |
| **RDS** | Database | ✅ Always created |
| **ALB** | Load balancer | ⏭️ Optional (disabled) |
| **Key Pair** | SSH access | ⏭️ Optional (disabled) |
| **ASG** | Auto scaling | ⏭️ Optional (depends on ALB) |
| **CloudFront** | CDN/caching | ⏭️ Optional (no domain) |
| **Route53** | DNS | ⏭️ Optional (no domain) |

---

## AWS Resource Naming Convention

Your resources will be named like:
- VPC: `10weeksofcloudops-demo-vpc`
- Subnets: `pub_sub_1a`, `pri_sub_5a`, etc.
- NAT Gateway: `nat-a`, `nat-b`
- RDS: `testdb` (default)
- ALB: `10weeksofcloudops-demo-alb` (if enabled)

This makes them easy to find in AWS Console!

---

## Files NOT to Commit to Git

These are already in .gitignore (safe):
- `.terraform/` - Terraform cache
- `*.tfstate*` - State files (contains secrets!)
- `*.tfvars*` - Variable files (contains passwords!)
- `.aws/credentials` - AWS credentials
- `*.pem` - Private keys
- `id_rsa*` - SSH keys

---

## Next Actions

1. **Right now:** Review the files created:
   - README-ISSUE.md (understand all errors)
   - DEPLOYMENT-GUIDE.md (deployment steps)
   - SOLUTIONS-SUMMARY.md (what changed)

2. **Then deploy:**
```bash
cd root/
terraform init
terraform plan
terraform apply
```

3. **Monitor in AWS Console:**
   - VPC Dashboard
   - RDS Dashboard
   - CloudWatch (for monitoring)

4. **Later, when ready:**
   - Enable ALB (get account permission)
   - Add EC2 key pair (generate SSH key)
   - Add CloudFront (get domain name)

---

## Key Learnings

✅ Use `count` to make resources optional
✅ Always run `terraform plan` before `apply`
✅ Keep credentials in `.gitignore`
✅ Make assumptions explicit in variables
✅ Document deployment steps
✅ Start simple, add features gradually
✅ Read error messages carefully

---

## Questions?

- **Deployment issues?** → See DEPLOYMENT-GUIDE.md
- **Error explanations?** → See README-ISSUE.md
- **Technical changes?** → See SOLUTIONS-SUMMARY.md
- **Quick lookup?** → You're reading it!

Good luck! 🚀

