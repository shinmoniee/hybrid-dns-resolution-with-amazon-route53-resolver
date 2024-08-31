variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr_cloud" {
  default = "10.0.0.0/16"
}

variable "vpc_cidr_onprem" {
  default = "172.16.0.0/16"
}

variable "subnet_cidrs_cloud" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "subnet_cidrs_onprem" {
  default = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "ssh_public_key" {
  default = "terraform-key.pub"
}

variable "ami_amazon_linux_2" {
  default = "ami-02c21308fed24a8ab"
}

variable "ami_ubuntu_22_04" {
  default = "ami-0a0e5d9c7acc336f1"
}