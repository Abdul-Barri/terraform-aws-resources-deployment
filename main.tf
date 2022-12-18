provider "aws" {
  region     = "us-east-1"
  access_key = "<access_key_string>"
  secret_key = "<secret_key_string>"

}

# 1. Create VPC

resource "aws_vpc" "terraform-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-terra"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "terraform-internet-gateway" {
  vpc_id = aws_vpc.terraform-vpc.id
  tags = {
    Name = "internet-gateway-terra"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "terraform-route-table" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-internet-gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.terraform-internet-gateway.id
  }

  tags = {
    Name = "route-table-terra"
  }
}

# 4. Create a Subnet

resource "aws_subnet" "terraform-subnet" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet-terra"
  }
}

# 5. Associate subnet with route table

resource "aws_route_table_association" "terraform-association" {
  subnet_id      = aws_subnet.terraform-subnet.id
  route_table_id = aws_route_table.terraform-route-table.id
}

# 6. Create Security Group to allow port 22, 80 and 443

resource "aws_security_group" "terraform-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http_https_terra"
  }
}

# 7. Create a Network Interface with an IP in the subnet that was created in step 4

resource "aws_network_interface" "terraform-network-interface" {
  subnet_id       = aws_subnet.terraform-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.terraform-security-grp-rule.id]
}

# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "terraform-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.terraform-network-interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.terraform-internet-gateway, aws_subnet.terraform-subnet, aws_instance.terraform-server]
  tags = {
    Name = "eip-terra"
  }
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "terraform-server" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "barraghanvirus"
  network_interface {
    network_interface_id = aws_network_interface.terraform-network-interface.id
    device_index         = 0
  }
  tags = {
    Name = "server-terra"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              EOF
}

# Prints out the Elastic IP 
output "server_public_ip" {
  value = aws_eip.terraform-eip.public_ip
}