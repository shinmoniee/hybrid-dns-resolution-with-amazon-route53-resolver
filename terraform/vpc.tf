resource "aws_vpc" "cloud_vpc" {
  cidr_block           = var.vpc_cidr_cloud
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Cloud-VPC"
  }
}

resource "aws_vpc" "onprem_vpc" {
  cidr_block           = var.vpc_cidr_onprem
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Onprem-VPC"
  }
}

resource "aws_vpc_dhcp_options" "onprem_dhcp_options" {
  domain_name         = "shinmoe.onprem"
  domain_name_servers = [aws_instance.onprem_dns.private_ip]
  ntp_servers         = ["169.254.169.123"] # AWS Time Sync server

  tags = {
    Name = "Onprem-DHCP-Options"
  }
}

resource "aws_vpc_dhcp_options_association" "onprem_dhcp_assoc" {
  vpc_id          = aws_vpc.onprem_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.onprem_dhcp_options.id
}

resource "aws_subnet" "cloud_subnets" {
  count             = length(var.subnet_cidrs_cloud)
  vpc_id            = aws_vpc.cloud_vpc.id
  cidr_block        = var.subnet_cidrs_cloud[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Cloud-Subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "onprem_subnets" {
  count             = length(var.subnet_cidrs_onprem)
  vpc_id            = aws_vpc.onprem_vpc.id
  cidr_block        = var.subnet_cidrs_onprem[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Onprem-Subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "cloud_igw" {
  vpc_id = aws_vpc.cloud_vpc.id

  tags = {
    Name = "Cloud-IGW"
  }
}

resource "aws_internet_gateway" "onprem_igw" {
  vpc_id = aws_vpc.onprem_vpc.id

  tags = {
    Name = "Onprem-IGW"
  }
}

resource "aws_route_table" "cloud_rt" {
  vpc_id = aws_vpc.cloud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_igw.id
  }

  tags = {
    Name = "Cloud-RT"
  }
}

resource "aws_route_table" "onprem_rt" {
  vpc_id = aws_vpc.onprem_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.onprem_igw.id
  }

  tags = {
    Name = "Onprem-RT"
  }
}

resource "aws_route_table_association" "cloud_rta" {
  count          = length(var.subnet_cidrs_cloud)
  subnet_id      = aws_subnet.cloud_subnets[count.index].id
  route_table_id = aws_route_table.cloud_rt.id
}

resource "aws_route_table_association" "onprem_rta" {
  count          = length(var.subnet_cidrs_onprem)
  subnet_id      = aws_subnet.onprem_subnets[count.index].id
  route_table_id = aws_route_table.onprem_rt.id
}

resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = aws_vpc.onprem_vpc.id
  vpc_id      = aws_vpc.cloud_vpc.id
  auto_accept = true

  tags = {
    Name = "VPC Peering between Cloud and Onprem"
  }
}

resource "aws_route" "cloud_to_onprem" {
  route_table_id            = aws_route_table.cloud_rt.id
  destination_cidr_block    = aws_vpc.onprem_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "onprem_to_cloud" {
  route_table_id            = aws_route_table.onprem_rt.id
  destination_cidr_block    = aws_vpc.cloud_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}