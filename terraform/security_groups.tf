# Cloud VPC Security Groups

resource "aws_security_group" "cloud_app_sg" {
  name        = "Cloud-App-SG"
  description = "Security group for cloud application instance"
  vpc_id      = aws_vpc.cloud_vpc.id

  # Allow inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound ICMP from On-premises VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_onprem]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Cloud-App-SG"
  }
}

resource "aws_security_group" "cloud_resolver_sg" {
  name        = "Cloud-Resolver-SG"
  description = "Security group for Route 53 Resolver endpoints"
  vpc_id      = aws_vpc.cloud_vpc.id

  # Allow inbound DNS traffic from on-premises VPC
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_onprem]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_onprem]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Cloud-Resolver-SG"
  }
}

# On-premises VPC Security Groups

resource "aws_security_group" "onprem_app_sg" {
  name        = "Onprem-App-SG"
  description = "Security group for on-premises application instance"
  vpc_id      = aws_vpc.onprem_vpc.id

  # Allow inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound ICMP from Cloud VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_cloud]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Onprem-App-SG"
  }
}

resource "aws_security_group" "onprem_dns_sg" {
  name        = "Onprem-DNS-SG"
  description = "Security group for on-premises DNS server"
  vpc_id      = aws_vpc.onprem_vpc.id

  # Allow inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound ICMP from Cloud VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_cloud]
  }

  # Allow inbound DNS traffic from on-premises VPC
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_onprem]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_onprem]
  }

  # Allow inbound DNS traffic from cloud VPC
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_cloud]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_cloud]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Onprem-DNS-SG"
  }
}