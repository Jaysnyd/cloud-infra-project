variable "aws_region" {
    description = "AWS region to deploy resources"
    default = "us-east-1"
}

variable "project_name" {
    description = "Name prefix for all resources"
    default = "cloud-infra-project"
}

variable "instance_type" {
    description = "EC2 instance type"
    default = "t3.micro"
}