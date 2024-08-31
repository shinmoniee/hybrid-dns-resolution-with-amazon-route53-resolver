resource "aws_route53_zone" "private" {
  name = "shinmoe.aws"

  vpc {
    vpc_id = aws_vpc.cloud_vpc.id
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.private.id
  name    = "app.shinmoe.aws"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.cloud_app.private_ip]
}

resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "inbound-endpoint"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.cloud_resolver_sg.id]

  ip_address {
    subnet_id = aws_subnet.cloud_subnets[0].id
    ip        = "10.0.1.20"
  }

  ip_address {
    subnet_id = aws_subnet.cloud_subnets[1].id
    ip        = "10.0.2.20"
  }
}

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "outbound-endpoint"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.cloud_resolver_sg.id]

  ip_address {
    subnet_id = aws_subnet.cloud_subnets[0].id
  }

  ip_address {
    subnet_id = aws_subnet.cloud_subnets[1].id
  }
}

resource "aws_route53_resolver_rule" "onprem" {
  domain_name          = "shinmoe.onprem"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = aws_instance.onprem_dns.private_ip
  }
  target_ip {
    ip = aws_instance.onprem_app.private_ip
  }
}

resource "aws_route53_resolver_rule_association" "onprem" {
  resolver_rule_id = aws_route53_resolver_rule.onprem.id
  vpc_id           = aws_vpc.cloud_vpc.id
}