# Provider 
# Tells Terraform which we're using AWS and which region to deploy to
provider "aws" {
  region = var.aws_region
}

# VPC 
# Private network inside AWS
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.project_name}-vpc"
    }
}

# Internet Gateway 
# Allows the VPC to communicate with the internet
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.project_name}-igw"
    }
}

# Subnet
# Smaller network range within my VPC
resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.project_name}-public-subnet"
    }
}

# Route Table
# Directs traffic traffic from subnet to the internet via the gateway
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${var.project_name}-public-rt"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.main.id
    route_table_id = aws_route_table.public.id
}

# Security Group
# Acts as a firewall 
resource "aws_security_group" "web" {
    name = "${var.project_name}-sg"
    description = "Allow HTTP and SSH traffic"
    vpc_id = aws_vpc.main.id

    # Allow SSH traffic
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
}

    # Allow HTTP traffic
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
}

    # Allow all outbound traffic
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-sg"
    }
}

# Key Pair 
# SSH key so we can connect to server
resource "aws_key_pair" "main" {
    key_name = "${var.project_name}-key"
    public_key = file("~/.ssh/cloud-infra-key.pub")
}

# EC2 Instance 
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["al2023-ami-*-x86_64"]
    }
}

resource "aws_instance" "web" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.main.id 
    vpc_security_group_ids = [aws_security_group.web.id]
    key_name = aws_key_pair.main.key_name

    tags = {
        Name = "${var.project_name}-server"
    }
}