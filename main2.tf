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

# Create an Elastic IP address that will be attached to the NAT Gateway 1

resource "aws_eip" "terraform-eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.terraform-internet-gateway]
  tags = {
    Name = "eip1-terra"
  }
}

# Create an Elastic IP address that will be attached to the NAT Gateway 2

resource "aws_eip" "terraform-eip2" {
  vpc        = true
  depends_on = [aws_internet_gateway.terraform-internet-gateway]
  tags = {
    Name = "eip2-terra"
  }
}

# Create a NAT Gateway 1

resource "aws_nat_gateway" "terraform-nat-gateway1" {
  allocation_id = aws_eip.terraform-eip1.id
  subnet_id     = aws_subnet.terraform-public-subnet1.id

  tags = {
    Name = "nat-gateway1-terra"
  }
  depends_on = [aws_internet_gateway.terraform-internet-gateway]
}

# Create a NAT Gateway 2

resource "aws_nat_gateway" "terraform-nat-gateway2" {
  allocation_id = aws_eip.terraform-eip2.id
  subnet_id     = aws_subnet.terraform-public-subnet2.id

  tags = {
    Name = "nat-gateway2-terra"
  }
  depends_on = [aws_internet_gateway.terraform-internet-gateway]
}

# Create public Route Table

resource "aws_route_table" "terraform-route-table-public" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-internet-gateway.id
  }

  tags = {
    Name = "route-table-public-terra"
  }
}

# Create private1 Route Table

resource "aws_route_table" "terraform-route-table-private1" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform-nat-gateway1.id
  }

  tags = {
    Name = "route-table-private1-terra"
  }
}

# Create private2 Route Table

resource "aws_route_table" "terraform-route-table-private2" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.terraform-nat-gateway2.id
  }

  tags = {
    Name = "route-table-private2-terra"
  }
}

# Associate public subnet 1 with public route table

resource "aws_route_table_association" "terraform-public-subnet1-association" {
  subnet_id      = aws_subnet.terraform-public-subnet1.id
  route_table_id = aws_route_table.terraform-route-table-public.id
}

# Associate public subnet 2 with public route table

resource "aws_route_table_association" "terraform-public-subnet2-association" {
  subnet_id      = aws_subnet.terraform-public-subnet2.id
  route_table_id = aws_route_table.terraform-route-table-public.id
}

# Associate private subnet 1 with private1 route table

resource "aws_route_table_association" "terraform-private-subnet1-association" {
  subnet_id      = aws_subnet.terraform-private-subnet1.id
  route_table_id = aws_route_table.terraform-route-table-private1.id
}

# Associate private subnet 2 with private2 route table

resource "aws_route_table_association" "terraform-private-subnet2-association" {
  subnet_id      = aws_subnet.terraform-private-subnet2.id
  route_table_id = aws_route_table.terraform-route-table-private2.id
}


# Create Public Subnet-1

resource "aws_subnet" "terraform-public-subnet1" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet1-terra"
  }
}

# Create Public Subnet-2

resource "aws_subnet" "terraform-public-subnet2" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "public-subnet2-terra"
  }
}

# Create Private Subnet-1

resource "aws_subnet" "terraform-private-subnet1" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet1-terra"
  }
}

# Create Private Subnet-2

resource "aws_subnet" "terraform-private-subnet2" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet2-terra"
  }
}

# Create a network ACL for the  two private subnets

resource "aws_network_acl" "terraform-network_acl" {
  vpc_id     = aws_vpc.terraform-vpc.id
  subnet_ids = [aws_subnet.terraform-private-subnet1.id, aws_subnet.terraform-private-subnet2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# Create a security group for the load balancer

resource "aws_security_group" "terraform-load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group to allow port 22, 80 and 443

resource "aws_security_group" "terraform-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.terraform-load_balancer_sg.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.terraform-load_balancer_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http_https_terra"
  }
}

# Create an Application Load Balancer

resource "aws_lb" "terraform-load-balancer" {
  name            = "loadbalancer-terra"
  internal        = false
  security_groups = [aws_security_group.terraform-load_balancer_sg.id]
  subnets         = [aws_subnet.terraform-public-subnet1.id, aws_subnet.terraform-public-subnet2.id]

  enable_deletion_protection = false
  depends_on                 = [aws_autoscaling_group.terraform-auto-scaling-grp]
}

# Create the target group

resource "aws_lb_target_group" "terraform-target-group" {
  name     = "target-group-terra"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
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

# Create the listener rule

resource "aws_lb_listener_rule" "terraform-listener-rule" {
  listener_arn = aws_lb_listener.terraform-listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-target-group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Creating EC2 launch template and auto-scaling group

resource "aws_launch_template" "terraform-launch-template" {
  name_prefix   = "hostname-launch-template"
  image_id      = "ami-0574da719dca65348"
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.terraform-security-grp-rule.id]
  }
  user_data              = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "terraform-auto-scaling-grp" {
  vpc_zone_identifier = [aws_subnet.terraform-private-subnet1.id, aws_subnet.terraform-private-subnet2.id]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2

  launch_template {
    id      = aws_launch_template.terraform-launch-template.id
    version = "$Latest"
  }
}

# Create a new ALB Target Group attachment

resource "aws_autoscaling_attachment" "terraform-asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.terraform-auto-scaling-grp.id
  lb_target_group_arn    = aws_lb_target_group.terraform-target-group.arn
}