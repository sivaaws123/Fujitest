module "label_vpc" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  context    = module.base_label.context
  name       = "vpc"
  attributes = ["main"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = module.label_vpc.tags
}

# =========================
# Create your subnets here
# =========================

# creating Public Sunbnet

resource "aws_subnet" "pubsubnet" {
  for_each          = var.pbsubnet
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value)
  availability_zone = data.aws_availability_zones.az.names[0]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
  depends_on = [aws_vpc.main]
}

# Creating Private Subnet
resource "aws_subnet" "privsnet" {
  for_each          = var.pvtsubnet
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value + 10)
  availability_zone = data.aws_availability_zones.az.names[0]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
  depends_on = [aws_vpc.main]
}

# Creating an Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "test_Igw"
  }
  depends_on = [aws_vpc.main]
}

# Create Route Table

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
  depends_on = [aws_internet_gateway.igw]
}

# Route Table Association to the public subnet to provide internet access

resource "aws_route_table_association" "rtbaso" {
  subnet_id      = aws_subnet.pubsubnet["public_subnet_1"].id
  route_table_id = aws_route_table.rtb.id
  depends_on     = [aws_route_table.rtb]
}

