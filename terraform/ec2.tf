resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "hybrid-dns-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/hybrid-dns-key.pem"
}

resource "aws_instance" "cloud_app" {
  ami                         = var.ami_amazon_linux_2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.cloud_subnets[0].id
  private_ip                  = "10.0.1.10"
  vpc_security_group_ids      = [aws_security_group.cloud_app_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key.key_name

  tags = {
    Name = "Cloud-App-Server"
  }
}

resource "aws_instance" "onprem_app" {
  ami                         = var.ami_amazon_linux_2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.onprem_subnets[0].id
  private_ip                  = "172.16.1.10"
  vpc_security_group_ids      = [aws_security_group.onprem_app_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key.key_name

  tags = {
    Name = "Onprem-App-Server"
  }
}

resource "aws_instance" "onprem_dns" {
  ami                         = var.ami_ubuntu_22_04
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.onprem_subnets[1].id
  vpc_security_group_ids      = [aws_security_group.onprem_dns_sg.id]
  associate_public_ip_address = true
  private_ip                  = "172.16.2.10"
  key_name                    = aws_key_pair.ssh_key.key_name

  tags = {
    Name = "Onprem-DNS-Server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y bind9 bind9utils",
    ]
  }

  provisioner "file" {
    source      = "../configs/named.conf"
    destination = "/tmp/named.conf"
  }

  provisioner "file" {
    source      = "../configs/named.conf.internal-zones"
    destination = "/tmp/named.conf.internal-zones"
  }

  provisioner "file" {
    source      = "../configs/shinmoe.onprem.lan"
    destination = "/tmp/shinmoe.onprem.lan"
  }

  provisioner "file" {
    source      = "../configs/named.conf.local"
    destination = "/tmp/named.conf.local"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/named.conf /etc/bind/named.conf",
      "sudo mv /tmp/named.conf.internal-zones /etc/bind/named.conf.internal-zones",
      "sudo mv /tmp/shinmoe.onprem.lan /etc/bind/shinmoe.onprem.lan",
      "sudo mv /tmp/named.conf.local /etc/bind/named.conf.local",
      "sudo sed -i 's/dnssec-validation auto;/dnssec-validation no;/g' /etc/bind/named.conf.options",
      "sudo sed -i \"/^options {/a\\    allow-query { ${var.vpc_cidr_cloud}; ${var.vpc_cidr_onprem}; };\" /etc/bind/named.conf.options",
      "sudo systemctl restart named",
      "sudo systemctl reboot",
    ]
  }
}