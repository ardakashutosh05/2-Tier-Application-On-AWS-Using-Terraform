# Deployment Guide & Solutions

This guide explains how to deploy the infrastructure with your AWS account limitations and provides solutions.

---

## Error 1: Load Balancer Not Supported

### What Happened?
```
Error: creating ELBv2 application Load Balancer (10weeksofcloudops-demo-alb): 
OperationNotPermitted: This AWS account currently does not support creating load balancers.
```

### Why Did This Happen?
- Your AWS account **doesn't have permission** to create Application Load Balancers (ALB)
- This is common on:
  - Free tier accounts
  - Trial accounts
  - Accounts with limited permissions
  - Accounts in certain regions

### Simple Explanation
Think of it like a restaurant that says: "We don't have the license to serve alcohol here"
Similarly, AWS is saying: "This account doesn't have permission to create load balancers"

### How We Fixed It
We made the ALB module **optional** using the `count` feature.

Now you can:
- ✅ Deploy WITHOUT ALB (default) - No errors!
- ✅ Enable ALB later when your account supports it

### How to Use It

**By Default (NO ALB):**
```hcl
deploy_alb = false
```
Just run:
```bash
terraform apply
```

**To Enable ALB (when account supports it):**
```hcl
deploy_alb = true
```
Then run:
```bash
terraform apply
```

---

## Error 2: Invalid SSH Key Format

### What Happened?
```
Error: importing EC2 Key Pair (client_key): InvalidKey.Format: 
Key is not in valid OpenSSH public key format
```

### Why Did This Happen?
The file `modules/key/client_key.pub` either:
- **Doesn't exist** (file is missing)
- **Is empty** (file has no content)
- **Has invalid format** (not a valid SSH public key)

### Simple Explanation
Imagine you're asked to import a photo, but you give an empty file or a text file.
The system says: "This is not a valid photo!"

Similarly, AWS expects a valid SSH public key but got something invalid.

### How We Fixed It
We made the EC2 Key Pair module **optional** using the `count` feature.

Now you can:
- ✅ Deploy WITHOUT EC2 key pair (default) - No errors!
- ✅ Create key pair later when you're ready

### How to Use It

**By Default (NO KEY PAIR):**
```hcl
deploy_key_pair = false
```
Just run:
```bash
terraform apply
```

**To Enable Key Pair (when you have valid key):**

1. Create a valid SSH key pair:
```bash
ssh-keygen -t rsa -b 4096 -f modules/key/client_key -N ""
```

2. This creates two files:
   - `modules/key/client_key` (private key - KEEP SECRET!)
   - `modules/key/client_key.pub` (public key)

3. Update terraform.tfvars:
```hcl
deploy_key_pair = true
```

4. Run:
```bash
terraform apply
```

---

## Current Recommended Deployment

For your AWS account with current limitations, use:

**terraform.tfvars:**
```hcl
db_username = "admin"
db_password = "admin"
region = "ap-southeast-1"
project_name = "10weeksofcloudops-demo"
vpc_cidr = "10.0.0.0/16"
pub_sub_1a_cidr = "10.0.1.0/24"
pub_sub_2b_cidr = "10.0.2.0/24"
pri_sub_3a_cidr = "10.0.3.0/24"
pri_sub_4b_cidr = "10.0.4.0/24"
pri_sub_5a_cidr = "10.0.5.0/24"
pri_sub_6b_cidr = "10.0.6.0/24"
certificate_domain_name = ""
additional_domain_name = ""
deploy_alb = false
deploy_key_pair = false
```

### What WILL Be Deployed ✅
- VPC with public and private subnets
- Internet Gateway (IGW)
- NAT Gateways (for private subnet internet access)
- Security Groups
- RDS Database

### What WON'T Be Deployed ⏭️
- Application Load Balancer (ALB) - Account limitation
- EC2 Key Pair - Key file not available
- Auto Scaling Group (ASG) - Depends on ALB/Key
- CloudFront - No domain specified
- Route53 - No domain specified

---

## Step-by-Step Deployment

### Step 1: Initialize Terraform
```bash
cd root/
terraform init
```

### Step 2: Validate Configuration
```bash
terraform validate
```
Expected output: `Success! The configuration is valid.`

### Step 3: See What Will Be Created
```bash
terraform plan
```
Review the resources that will be created.

### Step 4: Create Resources
```bash
terraform apply
```
When asked to confirm, type: `yes`

### Step 5: Wait for Completion
The process may take 5-10 minutes. You'll see each resource being created:
- Creating VPC...
- Creating Subnets...
- Creating NAT Gateways...
- Creating RDS...
- etc.

---

## Troubleshooting

### If You Get an Error After Applying

**Option 1: Skip the problematic resource**
Add to terraform.tfvars:
```hcl
deploy_alb = false
deploy_key_pair = false
```

**Option 2: Check AWS Account Permissions**
1. Go to AWS Management Console
2. Check your account type (Free Tier? Trial? Regular?)
3. Contact AWS Support if needed

**Option 3: Use Different Region**
Some regions have different service availability:
```hcl
region = "us-east-1"
```

---

## Enabling Features Later

### When You Want to Add ALB
1. Upgrade your AWS account or get proper permissions
2. Change terraform.tfvars:
```hcl
deploy_alb = true
```
3. Run:
```bash
terraform apply
```

### When You Want to Add Key Pair
1. Generate valid SSH key:
```bash
ssh-keygen -t rsa -b 4096 -f modules/key/client_key -N ""
```

2. Change terraform.tfvars:
```hcl
deploy_key_pair = true
```

3. Run:
```bash
terraform apply
```

### When You Want to Add CloudFront
1. Get a valid domain name
2. Create ACM certificate in AWS
3. Change terraform.tfvars:
```hcl
certificate_domain_name = "yourdomain.com"
additional_domain_name = "subdomain.yourdomain.com"
```

4. Run:
```bash
terraform apply
```

---

## Key Features of This Setup

| Feature | Status | How to Enable |
|---------|--------|---------------|
| VPC & Subnets | ✅ Always on | Set vpc_cidr |
| NAT Gateway | ✅ Always on | Automatic |
| RDS Database | ✅ Always on | Set db_username/password |
| ALB | ⏭️ Optional | `deploy_alb = true` |
| EC2 Key Pair | ⏭️ Optional | `deploy_key_pair = true` |
| CloudFront | ⏭️ Optional | Set certificate_domain_name |
| Route53 | ⏭️ Optional | Set certificate_domain_name |

---

## Best Practices

1. **Always run `terraform plan` before `terraform apply`**
   - This shows you exactly what will happen

2. **Keep terraform.tfvars safe**
   - It's in .gitignore (good!)
   - Never commit it to Git

3. **Start simple, add features gradually**
   - Deploy VPC first
   - Add ALB when account allows
   - Add key pair when file is ready
   - Add CloudFront when domain is ready

4. **Document your changes**
   - When you enable a feature, document why and when

5. **Test in a development account first**
   - Before using in production
   - Verify all features work as expected

---

## Common Questions

**Q: Can I deploy without RDS?**
A: Yes, you can modify the root/main.tf to comment out the RDS module if not needed.

**Q: Can I use the same ALB for multiple environments?**
A: Yes, but you'd need to modify the configuration and create separate Route53 records.

**Q: How do I destroy everything?**
A: Run `terraform destroy` (be careful - this deletes all resources!)

**Q: Can I import existing resources?**
A: Yes, use `terraform import` (advanced topic - see Terraform docs)

---

## Need Help?

1. Check the error message carefully
2. Read README-ISSUE.md for common issues
3. Run `terraform plan` to see what will happen
4. Contact AWS Support for account limitations
5. Check Terraform documentation: https://www.terraform.io/docs

