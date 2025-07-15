# VPC Configuration for DR Region (us-east-1)
resource "aws_vpc" "dr_vpc" {
  provider             = aws.dr
  cidr_block           = var.dr_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.app_name}-dr-vpc"
    Environment = var.environment
    Purpose     = "disaster-recovery"
  }
}

# Internet Gateway for DR VPC
resource "aws_internet_gateway" "dr_igw" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr_vpc.id

  tags = {
    Name        = "${var.app_name}-dr-igw"
    Environment = var.environment
  }
}

# Public Subnets for DR (ALB and NAT Gateways)
resource "aws_subnet" "dr_public_1" {
  provider                = aws.dr
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-dr-public-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "dr_public_2" {
  provider                = aws.dr
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-dr-public-2"
    Environment = var.environment
  }
}

# Private Subnets for DR (ECS Tasks and RDS)
resource "aws_subnet" "dr_private_1" {
  provider          = aws.dr
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "${var.app_name}-dr-private-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "dr_private_2" {
  provider          = aws.dr
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "${var.app_name}-dr-private-2"
    Environment = var.environment
  }
}

# Database Subnets for DR
resource "aws_subnet" "dr_db_1" {
  provider          = aws.dr
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.1.20.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "${var.app_name}-dr-db-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "dr_db_2" {
  provider          = aws.dr
  vpc_id            = aws_vpc.dr_vpc.id
  cidr_block        = "10.1.21.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "${var.app_name}-dr-db-2"
    Environment = var.environment
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "dr_public" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }

  tags = {
    Name        = "${var.app_name}-dr-public-rt"
    Environment = var.environment
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "dr_public_1" {
  provider       = aws.dr
  subnet_id      = aws_subnet.dr_public_1.id
  route_table_id = aws_route_table.dr_public.id
}

resource "aws_route_table_association" "dr_public_2" {
  provider       = aws.dr
  subnet_id      = aws_subnet.dr_public_2.id
  route_table_id = aws_route_table.dr_public.id
}

# NAT Gateway for Private Subnets
resource "aws_eip" "dr_nat" {
  provider = aws.dr
  domain   = "vpc"

  tags = {
    Name        = "${var.app_name}-dr-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "dr_nat" {
  provider      = aws.dr
  allocation_id = aws_eip.dr_nat.id
  subnet_id     = aws_subnet.dr_public_1.id

  tags = {
    Name        = "${var.app_name}-dr-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.dr_igw]
}

# Route Table for Private Subnets
resource "aws_route_table" "dr_private" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dr_nat.id
  }

  tags = {
    Name        = "${var.app_name}-dr-private-rt"
    Environment = var.environment
  }
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "dr_private_1" {
  provider       = aws.dr
  subnet_id      = aws_subnet.dr_private_1.id
  route_table_id = aws_route_table.dr_private.id
}

resource "aws_route_table_association" "dr_private_2" {
  provider       = aws.dr
  subnet_id      = aws_subnet.dr_private_2.id
  route_table_id = aws_route_table.dr_private.id
}

# Route Table for Database Subnets (No internet access)
resource "aws_route_table" "dr_db" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr_vpc.id

  tags = {
    Name        = "${var.app_name}-dr-db-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "dr_db_1" {
  provider       = aws.dr
  subnet_id      = aws_subnet.dr_db_1.id
  route_table_id = aws_route_table.dr_db.id
}

resource "aws_route_table_association" "dr_db_2" {
  provider       = aws.dr
  subnet_id      = aws_subnet.dr_db_2.id
  route_table_id = aws_route_table.dr_db.id
}
