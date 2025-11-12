# Issue 6: Auto Scaling Group (ASG) Error

## Error Message

```
Error: creating Auto Scaling Group (10weeksofcloudops-demo-asg): ValidationError: 
You must use a valid fully-formed launch template. The request must contain the parameter ImageId
```

---

## What Happened?

The ASG module tried to create a launch template without an **AMI ID** (Amazon Machine Image).

AWS couldn't find the required ImageId parameter and rejected the request.

---

## Why Did This Happen?

### Root Causes:
1. **No AMI ID provided** - The variable `ami` was empty
2. **No default AMI set** - The ASG module expected someone to provide one
3. **Missing dependencies** - ALB and Key Pair weren't created, so ASG couldn't work anyway

### The Dependency Chain:
```
┌─────────────────┐
│  ALB (disabled) │
└────────┬────────┘
         │
      ┌──▼──┐
      │ ASG │ ◄─ Can't create without these!
      └──┬──┘
         │
┌────────▼────────┐
│ Key Pair        │
│ (disabled)      │
└─────────────────┘
```

---

## Simple Explanation

Imagine a pizza restaurant:
- To make pizza, you need **3 things:**
  - ✅ Chef (ALB - load balancer)
  - ✅ Recipe/ingredients (Key Pair - to access servers)
  - ✅ Oven type (AMI ID - which operating system)

If ANY are missing, you can't make pizza!

Similarly, ASG needs all three to create instances.

---

## How We Fixed It

We made the ASG module **optional** using `count`.

### Changes Made:

1. **Added variable to root/variables.tf:**
```hcl
variable deploy_asg { default = false }
```

2. **Made ASG optional in root/main.tf:**
```hcl
module "asg" {
  count = var.deploy_asg ? 1 : 0
  # ... rest of config
}
```

3. **Disabled by default in terraform.tfvars:**
```hcl
deploy_asg = false
```

---

## Current Behavior

### What Gets Created Now ✅
- VPC, Subnets, NAT, Security Groups
- RDS Database
- (Optional) ALB, CloudFront, Route53

### What Doesn't Get Created ⏭️
- **Auto Scaling Group (ASG)** - Disabled by default
- EC2 instances (depend on ASG)
- Launch template (depends on ASG)

---

## How to Enable ASG Later

### Step 1: Enable Prerequisites

First, you need ALB and Key Pair:

**In terraform.tfvars:**
```hcl
deploy_alb = true
deploy_key_pair = true
```

### Step 2: Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f modules/key/client_key -N ""
```

### Step 3: Get a Valid AMI ID

Find an AMI ID for your region. Examples:
- **ap-southeast-1** (Singapore):
  - Ubuntu 22.04: `ami-0d3f95db14c4c1bf7`
  - Amazon Linux 2: `ami-0863b89b3f7d85e8f`

- **us-east-1** (N. Virginia):
  - Ubuntu 22.04: `ami-0c55b159cbfafe1f0`
  - Amazon Linux 2: `ami-0c02fb55956c7d316`

**To find your region's AMI ID:**
1. Go to AWS EC2 Console
2. Click "Launch Instance"
3. Search for "Ubuntu 22.04" or your OS
4. Copy the AMI ID shown

### Step 4: Enable ASG in terraform.tfvars

```hcl
deploy_asg = true
ami = "ami-0123456789abcdef0"  # Replace with your AMI ID
```

### Step 5: Configure ASG (Optional)

You can customize these in terraform.tfvars:

```hcl
# In modules/asg/variables_extra.tf defaults:
# - cpu: instance type (default: t2.micro)
# - max_size: max instances (default: 2)
# - min_size: min instances (default: 1)  
# - desired_cap: desired instances (default: 1)
```

### Step 6: Deploy

```bash
cd root/
terraform apply
```

---

## Common Scenarios

### Scenario 1: Just VPC & Database (Free Tier Safe)
```hcl
deploy_alb = false
deploy_key_pair = false
deploy_asg = false
```
✅ Creates: VPC, Subnets, RDS
⏭️ Skips: Everything else

### Scenario 2: Full Stack with ASG
```hcl
deploy_alb = true
deploy_key_pair = true
deploy_asg = true
ami = "ami-0123456789abcdef0"
```
✅ Creates: VPC, Subnets, ALB, Key Pair, ASG, Instances, RDS
⏭️ Skips: CloudFront, Route53 (no domain)

### Scenario 3: ALB Only (Testing Load Balancer)
```hcl
deploy_alb = true
deploy_key_pair = false
deploy_asg = false
```
✅ Creates: VPC, Subnets, ALB, Security Groups, RDS
⏭️ Skips: Key Pair, ASG, EC2 Instances

---

## Troubleshooting

### Error: "You must use a valid fully-formed launch template"
**Solution:** Set `deploy_asg = false` (already done by default)

### Error: "This is an invalid AMI ID"
**Solution:** 
1. Check the AMI ID is for your region
2. Check the AMI still exists (old AMIs get deprecated)
3. Get a new AMI ID from AWS console

### Error: "No key pair found"
**Solution:** Generate the key pair first:
```bash
ssh-keygen -t rsa -b 4096 -f modules/key/client_key -N ""
```

### Error: "Cannot find target group"
**Solution:** Enable ALB first:
```hcl
deploy_alb = true
```

---

## Advanced: Custom ASG Configuration

If you enable ASG, you can customize it in `root/terraform.tfvars`:

```hcl
# Instance type (t2.micro is free tier eligible)
# t2.micro, t2.small, t3.micro, etc.

# If not already set, add to terraform.tfvars:
# (Variables are in modules/asg/variables_extra.tf)
```

---

## How to Check What Will Happen

Before enabling ASG:

```bash
cd root/
terraform plan -out=plan.tfplan
```

This shows exactly what will be created:
- How many instances?
- What resources?
- What costs?

Review before running `terraform apply`!

---

## Cost Implications

⚠️ **WARNING:** Enabling ASG creates EC2 instances, which **incur costs**!

### Estimated Costs (approximate, varies by region):
- **t2.micro (1 instance):** ~$0-10/month (free tier eligible for first 12 months)
- **t2.micro (2 instances):** ~$10-20/month
- **t3.micro (1 instance):** ~$5-15/month

**Recommendation:** Start with 1 instance (`desired_cap = 1`) to test.

---

## Best Practices

✅ **DO:**
- Deploy without ASG first, test everything
- Enable dependencies (ALB, Key) before ASG
- Use t2.micro for testing (free tier eligible)
- Run `terraform plan` before `terraform apply`
- Set `desired_cap = 1` for testing
- Destroy resources when not in use (`terraform destroy`)

❌ **DON'T:**
- Enable ASG without ALB and Key Pair
- Use invalid AMI IDs from other regions
- Leave instances running if not needed (costs money!)
- Forget to run `terraform destroy` when done testing
- Use high-capacity settings for testing (expensive!)

---

## Next Steps

1. ✅ For now: Deploy without ASG (works great!)
2. When ready: Enable ALB and Key Pair
3. When you have AMI: Enable ASG
4. When done testing: Run `terraform destroy`

---

## Questions?

- **How do I find my AMI?** → See "Get a Valid AMI ID" section
- **Will this cost money?** → Yes, EC2 instances incur costs
- **Can I test without ASG?** → Yes! VPC + RDS work great
- **How do I destroy it?** → Run `terraform destroy`
- **How do I update settings?** → Edit terraform.tfvars and run `terraform apply`

