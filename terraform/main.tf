terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Rocky Linux 8 AMI — free, official, no marketplace fees
data "aws_ami" "rocky8" {
  most_recent = true
  owners      = ["792107900819"]

  filter {
    name   = "name"
    values = ["Rocky-8-EC2-Base-8*x86_64*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# VPC
resource "aws_vpc" "lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "devsecops-lab"
    Environment = "lab"
    Project     = "devsecops-platform-lab"
  }
}

# Subnet
resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "devsecops-lab-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "devsecops-lab-igw"
  }
}
# Route Table
resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }

  tags = {
    Name = "devsecops-lab-rt"
  }
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

# Key Pair
resource "aws_key_pair" "lab" {
  key_name   = "devsecops-lab-key"
  public_key = file(var.public_key_path)
}

# Control Plane
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.rocky8.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.lab.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  key_name               = aws_key_pair.lab.key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s_node.name

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "k8s-control-plane"
    Role = "control-plane"
  }
}

# Worker Node
resource "aws_instance" "worker" {
  ami                    = data.aws_ami.rocky8.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.lab.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  key_name               = aws_key_pair.lab.key_name
  iam_instance_profile   = aws_iam_instance_profile.k8s_node.name

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "k8s-worker"
    Role = "worker"
  }
}