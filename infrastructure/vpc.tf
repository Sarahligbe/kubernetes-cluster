resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr_block
  enable_dns_hostnames  = true
  enable_dns_support = true
  tags = {
    Name                = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}"      = "owned"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each              = var.private_subnet_blocks

  vpc_id                = aws_vpc.main.id
  cidr_block            = each.value["cidr"]
  availability_zone     = each.value["az"]

  tags = {
    Name                = each.key
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "owned"
    
  }
}

resource "aws_subnet" "public_subnets" {
  for_each              = var.public_subnet_blocks

  vpc_id                = aws_vpc.main.id
  cidr_block            = each.value["cidr"]
  availability_zone     = each.value["az"]

  tags = {
    Name                = each.key
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
  }
}

resource "aws_subnet" "intra_subnets" {
  for_each              = var.intra_subnet_blocks

  vpc_id                = aws_vpc.main.id
  cidr_block            = each.value["cidr"]
  availability_zone     = each.value["az"]

  tags = {
    Name                = each.key
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id                = aws_vpc.main.id

  tags = {
    Name                = "${var.cluster_name}-igw"
  }
}

resource "aws_eip" "main" {
  vpc = true

  tags = {
    Name = "${var.cluster_name}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

output "first_priv_subnet" {
  value = aws_subnet.public_subnets[keys(aws_subnet.public_subnets)[0]].id
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id = aws_subnet.public_subnets[keys(aws_subnet.public_subnets)[0]].id

  tags = {
    Name = "${var.cluster_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public_rtb" {
  vpc_id                = aws_vpc.main.id

  route {
    cidr_block          = "0.0.0.0/0"
    gateway_id          = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.cluster_name}-public"
  }
}

resource "aws_route_table" "private_rtb" {
  vpc_id                = aws_vpc.main.id

  route {
    cidr_block          = "0.0.0.0/0"
    nat_gateway_id          = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.cluster_name}-private"
  }
}

resource "aws_route_table_association" "public_rtb" {
  for_each              = aws_subnet.public_subnets

  subnet_id             = each.value.id
  route_table_id        = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "private_rtb" {
  for_each              = aws_subnet.private_subnets

  subnet_id             = each.value.id
  route_table_id        = aws_route_table.private_rtb.id
}



