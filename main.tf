provider "aws" {
  region     = "us-east-1"
  access_key = "<access_key_value>"
  secret_key = "<secret_key_value>"

}

# Create VPC

resource "aws_vpc" "terraform-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-terra"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "terraform-internet-gateway" {
  vpc_id = aws_vpc.terraform-vpc.id
  tags = {
    Name = "internet-gateway-terra"
  }
}

# Create Custom Route Table

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

# Create Subnet-1

resource "aws_subnet" "terraform-subnet1" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "subnet1-terra"
  }
}

# Create Subnet-2

resource "aws_subnet" "terraform-subnet2" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "subnet2-terra"
  }
}

# Create a Subnet-3

resource "aws_subnet" "terraform-subnet3" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  tags = {
    Name = "subnet3-terra"
  }
}

# Associate subnet 1 with route table

resource "aws_route_table_association" "terraform-subnet1-association" {
  subnet_id      = aws_subnet.terraform-subnet1.id
  route_table_id = aws_route_table.terraform-route-table.id
}

# Associate subnet 2 with route table

resource "aws_route_table_association" "terraform-subnet2-association" {
  subnet_id      = aws_subnet.terraform-subnet2.id
  route_table_id = aws_route_table.terraform-route-table.id
}

# Associate subnet 3 with route table

resource "aws_route_table_association" "terraform-subnet3-association" {
  subnet_id      = aws_subnet.terraform-subnet3.id
  route_table_id = aws_route_table.terraform-route-table.id
}

# Create Security Group to allow port 22, 80 and 443

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

# Create a Network Interface with an IP in subnet 1 

resource "aws_network_interface" "terraform-network1-interface" {
  subnet_id       = aws_subnet.terraform-subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.terraform-security-grp-rule.id]
}

# Create a Network Interface with an IP in subnet 2

resource "aws_network_interface" "terraform-network2-interface" {
  subnet_id       = aws_subnet.terraform-subnet2.id
  private_ips     = ["10.0.2.50"]
  security_groups = [aws_security_group.terraform-security-grp-rule.id]
}

# Create a Network Interface with an IP in subnet 3

resource "aws_network_interface" "terraform-network3-interface" {
  subnet_id       = aws_subnet.terraform-subnet3.id
  private_ips     = ["10.0.3.50"]
  security_groups = [aws_security_group.terraform-security-grp-rule.id]
}

# Assign an elastic IP to the network interface created in step 7

# resource "aws_eip" "terraform-eip" {
#   vpc                       = true
#   network_interface         = aws_network_interface.terraform-network-interface.id
#   associate_with_private_ip = "10.0.1.50"
#   depends_on                = [aws_internet_gateway.terraform-internet-gateway, aws_subnet.terraform-subnet, aws_instance.terraform-server]
#   tags = {
#     Name = "eip-terra"
#   }
# }

# Create Ubuntu server 1 and install/enable nginx

resource "aws_instance" "terraform-server1" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "barraghanvirus"
  network_interface {
    network_interface_id = aws_network_interface.terraform-network1-interface.id
    device_index         = 0
  }
  tags = {
    Name = "server-terra1"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                EOF
}

# Create Ubuntu server 2 and install/enable nginx

resource "aws_instance" "terraform-server2" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1b"
  key_name          = "barraghanvirus"
  network_interface {
    network_interface_id = aws_network_interface.terraform-network2-interface.id
    device_index         = 0
  }
  tags = {
    Name = "server-terra2"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                EOF
}

# Create Ubuntu server 3 and install/enable nginx

resource "aws_instance" "terraform-server3" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1c"
  key_name          = "barraghanvirus"
  network_interface {
    network_interface_id = aws_network_interface.terraform-network3-interface.id
    device_index         = 0
  }
  tags = {
    Name = "server-terra3"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                EOF
}

# Create an Application Load Balancer

resource "aws_lb" "terraform-load-balancer" {
  name               = "loadbalancer-terra"
  internal           = false
  security_groups    = [aws_security_group.terraform-security-grp-rule.id]
  subnets            = [aws_subnet.terraform-subnet1.id, aws_subnet.terraform-subnet2.id, aws_subnet.terraform-subnet3.id]

  enable_deletion_protection = false
}

# Create the target group

resource "aws_lb_target_group" "terraform-target-group" {
  name     = "target-group-terra"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id
}

# Create the listener

resource "aws_lb_listener" "terraform-listener" {
  load_balancer_arn = aws_lb.terraform-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-target-group.arn
  }
}

# Attach the target group to the load balancer

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform1" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id      = aws_instance.terraform-server1.id
  port           = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform2" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id      = aws_instance.terraform-server2.id
  port           = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform3" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id      = aws_instance.terraform-server3.id
  port           = 80
}