terraform {
  required_providers {
    aws = {
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Optional trigger to inject SSM endpoints for using SSM to manage instances
module "ssm_endpoints" {
  source              = "./modules/ssm_endpoints"
  enable_ssm_endpoints = var.enable_ssm_endpoints
  vpc_id              = aws_vpc.main.id
  subnet_ids          = aws_subnet.web[*].id
  web_instance_sg_id  = aws_security_group.web_instance.id
  environment         = var.environment
  aws_region          = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

## Subnets

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.${count.index * 32}/27"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "public"
  }
}

resource "aws_subnet" "web" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.${64 + count.index * 32}/27"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-web-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "web"
  }
}

resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.${128 + count.index * 32}/27"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-app-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "app"
  }
}

## Route Tables

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "web" {
  count  = 2
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-web-rt-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "web" {
  count          = 2
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.web[count.index].id
}

resource "aws_route_table" "app" {
  count  = 2
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-app-rt-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "app" {
  count          = 2
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids    = aws_route_table.web[*].id

  tags = {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
  }
}