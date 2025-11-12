# Issues Found & How to Fix Them

This document explains the issues we faced during the Terraform deployment and how to prevent them in the future.

---

## Issue 1: Missing Resource Instance Key Error

### What Happened?
```
Error: Missing resource instance key
  on ../modules/cloudfront/main.tf line 44, in resource "aws_cloudfront_distribution" "my_distribution":
   44:     acm_certificate_arn      = data.aws_acm_certificate.issued.arn

Because data.aws_acm_certificate.issued has "count" set, its attributes must be accessed on specific instances.
```

### Why Did This Happen?
- The code was trying to access `data.aws_acm_certificate.issued.arn` 
- But the data source was commented out (not active)
- When you reference a data source that uses `count`, you MUST add an index like `[0]`
- The index `[0]` means "use the first instance"

### Simple Explanation
Think of it like this:
- If you have ONE thing, you can say "give me the thing"
- If you have MANY things (using `count`), you must say "give me thing #1, thing #2, etc."

### How We Fixed It
1. **Uncommented** the data source so it's active
2. **Removed the `[0]` index** because the data source doesn't actually use `count`

### How to Avoid This in Future
✅ **DO:** If using `count`, always use index like `data.something[0].property`
❌ **DON'T:** Mix commented and uncommented code - it causes confusion
✅ **DO:** Check if your data source actually has `count` before adding an index

---

## Issue 2: Duplicate Data Source Configuration

### What Happened?
```
Error: Duplicate data "aws_acm_certificate" configuration
  on ../modules/cloudfront/main.tf line 2:
   2: data "aws_acm_certificate" "issued" {

A aws_acm_certificate data resource named "issued" was already declared at ../modules/cloudfront/acm_data.tf:1,1-36.
```

### Why Did This Happen?
- The same data source was defined in TWO files:
  - `acm_data.tf` 
  - `main.tf`
- Terraform doesn't allow the same resource to be declared twice
- Each resource must have a unique name in the module

### Simple Explanation
You can't have two people with the same name in the same room. Similarly, you can't declare the same resource twice in the same module.

### How We Fixed It
- **Deleted** the duplicate data source from `main.tf`
- **Kept** the data source definition in `acm_data.tf`
- **Kept** the reference to it in the CloudFront resource

### How to Avoid This in Future
✅ **DO:** Organize your code - put data sources in one file (like `data.tf` or `acm_data.tf`)
✅ **DO:** Put resources in another file (like `main.tf`)
✅ **DO:** Search your module folder before adding new code
❌ **DON'T:** Copy-paste code without checking if it already exists

---

## Issue 3: No ACM Certificate Matching Domain

### What Happened?
```
Error: no ACM Certificate matching domain ()
  with module.cloudfront.data.aws_acm_certificate.issued,
  on ../modules/cloudfront/main.tf line 2
```

### Why Did This Happen?
- The variable `certificate_domain_name` was **empty** (had no value)
- Terraform tried to find an ACM certificate for an empty domain name
- AWS couldn't find a certificate for nothing, so it failed

### Simple Explanation
Imagine asking someone: "Can you find the book called... ?" (you don't say the name)
They'll say: "Which book? You didn't tell me the name!"

---

## Issue 4: No Matching Route53 Zone Found

### What Happened?
```
Error: no matching Route53Zone found
  with module.route53.data.aws_route53_zone.public-zone,
  on ../modules/route53/main.tf line 2
```

### Why Did This Happen?
- The variable `hosted_zone_name` was not provided or was empty
- Terraform tried to find a Route53 hosted zone that doesn't exist
- This happened because the domain variables were not set in `terraform.tfvars`

### Simple Explanation
You're trying to find a house in a city that doesn't exist. The house can't be found if the city name is wrong or missing.

---

## Issue 5: Invalid CIDR Address (Empty Value)

### What Happened?
```
Error: expected cidr_block to contain a valid Value, got:  with err: invalid CIDR address:
  with module.vpc.aws_vpc.vpc,
  on ../modules/vpc/main.tf line 3:
   3:   cidr_block              = var.vpc_cidr
```

### Why Did This Happen?
- The variable `vpc_cidr` in `terraform.tfvars` was empty: `vpc_cidr = ""`
- CIDR block must have a valid format like `10.0.0.0/16`
- AWS doesn't allow empty network addresses

### Simple Explanation
A CIDR block is like a home address. It must follow a specific format:
- ✅ Valid: `10.0.0.0/16` (This is a real address)
- ❌ Invalid: `` (Empty - not an address at all)

### How We Fixed It
We added all the required CIDR values to `terraform.tfvars`:
```hcl
vpc_cidr      = "10.0.0.0/16"
pub_sub_1a_cidr = "10.0.1.0/24"
pub_sub_2b_cidr = "10.0.2.0/24"
pri_sub_3a_cidr = "10.0.3.0/24"
pri_sub_4b_cidr = "10.0.4.0/24"
pri_sub_5a_cidr = "10.0.5.0/24"
pri_sub_6b_cidr = "10.0.6.0/24"
```

---

## Solution: Made CloudFront & Route53 Optional

### What We Did
Since you don't have a valid certificate domain, we made CloudFront and Route53 **optional** using Terraform's `count` feature.

### How It Works
In `root/main.tf`:
```hcl
module "cloudfront" {
  count = var.certificate_domain_name != "" ? 1 : 0
  # ... rest of config
}
```

### Simple Explanation
This says: "Only create CloudFront IF the certificate_domain_name is not empty"
- If you provide a domain name → CloudFront gets created ✅
- If domain name is empty → CloudFront is skipped ⏭️

### Result
- ✅ VPC, Subnets, NAT, Security Groups, ALB, ASG, and RDS deploy successfully
- ⏭️ CloudFront and Route53 are skipped (no errors)
- 🎯 You can add them later when you have a valid domain

---

## How to Use This Setup Going Forward

### To Deploy WITHOUT Certificate/Domain
```bash
terraform init
terraform plan
terraform apply
```
Leave these empty in `terraform.tfvars`:
```hcl
certificate_domain_name = ""
additional_domain_name = ""
```

### To Add CloudFront & Route53 Later
1. Get a valid domain name
2. Create an ACM certificate in AWS for that domain
3. Update `terraform.tfvars`:
```hcl
certificate_domain_name = "example.com"
additional_domain_name = "subdomain.example.com"
```
4. Re-run `terraform apply`

---

## Common Mistakes to Avoid

| ❌ WRONG | ✅ CORRECT |
|---------|-----------|
| Leaving variables empty without providing defaults | Provide sensible defaults or make the feature optional with `count` |
| Defining same resource in multiple files | Define each resource only once, organize into logical files |
| Using `[0]` index when `count` is not set | Only use `[index]` if `count` is actually set on the resource |
| Not checking if resource already exists | Search your code before copy-pasting |
| Ignoring empty variable values | Always validate that required variables have values |
| Committing credentials to Git | Add all sensitive files to `.gitignore` |

---

## Testing Your Changes

After making changes, always:
1. **Validate**: `terraform validate` (checks for syntax errors)
2. **Plan**: `terraform plan` (shows what will be created/changed)
3. **Apply**: `terraform apply` (actually creates resources)

Example:
```bash
cd root/
terraform validate
terraform plan
terraform apply
```

---

## Key Learnings

1. **Empty variables cause errors** → Always provide values or handle them with `count`
2. **Duplicate code causes conflicts** → Keep your code organized and DRY (Don't Repeat Yourself)
3. **Use `count` for optional resources** → It's the Terraform way to make features optional
4. **Read error messages carefully** → They tell you exactly what's wrong and where
5. **CIDR blocks need valid format** → Check AWS documentation for valid network ranges

---

## Questions?

If you encounter similar issues:
1. Read the error message carefully
2. Check if a variable is empty
3. Search for duplicate resource definitions
4. Validate your CIDR block format
5. Use `terraform plan` to see what will happen before applying

