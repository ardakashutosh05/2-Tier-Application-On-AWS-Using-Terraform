output "region" {
    value = var.region
}

output "project_name" {
    value = var.project_name
}

output "vpc_id" {
    value = module.vpc.vpc_id
}

output "pub_sub_1a_id" {
    value = module.vpc.pub_sub_1a_id
}

output "pub_sub_2b_id" {
    value = module.vpc.pub_sub_2b_id
}

output "pri_sub_3a_id" {
    value = module.vpc.pri_sub_3a_id
}

output "pri_sub_4b_id" {
    value = module.vpc.pri_sub_4b_id
}

output "pri_sub_5a_id" {
    value = module.vpc.pri_sub_5a_id
}

output "pri_sub_6b_id" {
    value = module.vpc.pri_sub_6b_id
}

output "igw_id" {
    value = aws_internet_gateway.igw  
}
