module "vpc" {
    source = "../modules/vpc"
    region = var.region
    project_name = var.project_name
    vpc_cidr         = var.vpc_cidr
    pub_sub_1a_cidr = var.pub_sub_1a_cidr
    pub_sub_2b_cidr = var.pub_sub_2b_cidr
    pri_sub_3a_cidr = var.pri_sub_3a_cidr
    pri_sub_4b_cidr = var.pri_sub_4b_cidr
    pri_sub_5a_cidr = var.pri_sub_5a_cidr
    pri_sub_6b_cidr = var.pri_sub_6b_cidr
}

module "nat" {
  source = "../modules/nat"

  pub_sub_1a_id = module.vpc.pub_sub_1a_id
  igw_id        = module.vpc.igw_id
  pub_sub_2b_id = module.vpc.pub_sub_2b_id
  vpc_id        = module.vpc.vpc_id
  pri_sub_3a_id = module.vpc.pri_sub_3a_id
  pri_sub_4b_id = module.vpc.pri_sub_4b_id
  pri_sub_5a_id = module.vpc.pri_sub_5a_id
  pri_sub_6b_id = module.vpc.pri_sub_6b_id
}

module "security-group" {
  source = "../modules/security-group"
  vpc_id = module.vpc.vpc_id
}

# creating Key for instances
module "key" {
  count  = var.deploy_key_pair ? 1 : 0
  source = "../modules/key"
}

# Creating Application Load balancer
module "alb" {
  count          = var.deploy_alb ? 1 : 0
  source         = "../modules/alb"
  project_name   = module.vpc.project_name
  alb_sg_id      = module.security-group.alb_sg_id
  pub_sub_1a_id = module.vpc.pub_sub_1a_id
  pub_sub_2b_id = module.vpc.pub_sub_2b_id
  vpc_id         = module.vpc.vpc_id
}

module "asg" {
  count          = var.deploy_asg ? 1 : 0
  source         = "../modules/asg"
  project_name   = module.vpc.project_name
  key_name       = var.deploy_key_pair ? module.key[0].key_name : ""
  client_sg_id   = module.security-group.client_sg_id
  pri_sub_3a_id = module.vpc.pri_sub_3a_id
  pri_sub_4b_id = module.vpc.pri_sub_4b_id
  tg_arn         = var.deploy_alb ? module.alb[0].tg_arn : ""

}

# creating RDS instance

module "rds" {
  source         = "../modules/rds"
  db_sg_id       = module.security-group.db_sg_id
  pri_sub_5a_id = module.vpc.pri_sub_5a_id
  pri_sub_6b_id = module.vpc.pri_sub_6b_id
  db_username    = var.db_username
  db_password    = var.db_password
}


# create cloudfront distribution 
module "cloudfront" {
  count = var.certificate_domain_name != "" ? 1 : 0
  
  source = "../modules/cloudfront"
  certificate_domain_name = var.certificate_domain_name
  alb_domain_name = var.deploy_alb ? module.alb[0].alb_dns_name : "example.com"
  additional_domain_name = var.additional_domain_name
  project_name = module.vpc.project_name
}


# Add record in route 53 hosted zone

module "route53" {
  count = var.certificate_domain_name != "" ? 1 : 0
  
  source = "../modules/route53"
  cloudfront_domain_name = module.cloudfront[0].cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cloudfront[0].cloudfront_hosted_zone_id

}