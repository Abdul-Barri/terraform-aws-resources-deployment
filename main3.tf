provider "aws" {
  region     = "us-east-1"
  access_key = "<access_key"
  secret_key = "secret_key"

}

# Create VPC

resource "aws_vpc" "terraform-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "terra-vpc"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "terraform-internet-gateway" {
  vpc_id = aws_vpc.terraform-vpc.id
  tags = {
    Name = "terra-internet-gateway"
  }
}

# Create public Route Table

resource "aws_route_table" "terraform-route-table-public" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-internet-gateway.id
  }

  tags = {
    Name = "terra-route-table-public"
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

# Associate public subnet 3 with public route table

resource "aws_route_table_association" "terraform-public-subnet3-association" {
  subnet_id      = aws_subnet.terraform-public-subnet3.id
  route_table_id = aws_route_table.terraform-route-table-public.id
}


# Create Public Subnet-1

resource "aws_subnet" "terraform-public-subnet1" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "terra-public-subnet1"
  }
}

# Create Public Subnet-2

resource "aws_subnet" "terraform-public-subnet2" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "terra-public-subnet2"
  }
}

# Create Public Subnet-3

resource "aws_subnet" "terraform-public-subnet3" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"
  tags = {
    Name = "terra-public-subnet3"
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

# Create a instance1

resource "aws_instance" "terraform-instance1" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "barraghanvirus"
  subnet_id         = aws_subnet.terraform-public-subnet1.id
  security_groups   = [aws_security_group.terraform-security-grp-rule.id]
  tags = {
    Name = "instance1-terra"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install nginx -y
                sudo systemctl start nginx.service
                sudo systemctl enable nginx.service
                host=$(hostname)
                ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
                sudo chown -R $USER:$USER /var/www
                echo 'Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html
                EOF
}

# Create a instance2

resource "aws_instance" "terraform-instance2" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1b"
  key_name          = "barraghanvirus"
  subnet_id         = aws_subnet.terraform-public-subnet2.id
  security_groups   = [aws_security_group.terraform-security-grp-rule.id]
  tags = {
    Name = "instance2-terra"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install nginx -y
                sudo systemctl start nginx.service
                sudo systemctl enable nginx.service
                host=$(hostname)
                ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
                sudo chown -R $USER:$USER /var/www
                echo 'Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html
                EOF
}

# Create a instance3

resource "aws_instance" "terraform-instance3" {
  ami               = "ami-0574da719dca65348"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1c"
  key_name          = "barraghanvirus"
  subnet_id         = aws_subnet.terraform-public-subnet3.id
  security_groups   = [aws_security_group.terraform-security-grp-rule.id]
  tags = {
    Name = "instance3-terra"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install nginx -y
                sudo systemctl start nginx.service
                sudo systemctl enable nginx.service
                host=$(hostname)
                ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
                sudo chown -R $USER:$USER /var/www
                echo 'Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html
                EOF
}

# Create an Application Load Balancer

resource "aws_lb" "terraform-load-balancer" {
  name            = "loadbalancer-terra"
  internal        = false
  security_groups = [aws_security_group.terraform-load_balancer_sg.id]
  subnets         = [aws_subnet.terraform-public-subnet1.id, aws_subnet.terraform-public-subnet2.id, aws_subnet.terraform-public-subnet3.id]

  enable_deletion_protection = false
  depends_on                 = [aws_instance.terraform-instance1, aws_instance.terraform-instance2, aws_instance.terraform-instance3]
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


# Attach the target group to the load balancer

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform1" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id        = aws_instance.terraform-instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform2" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id        = aws_instance.terraform-instance2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform3" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id        = aws_instance.terraform-instance3.id
  port             = 80
}

resource "local_file" "ip_address" {
  filename = "/home/abdul-barri/terraform/altschool-exercises/host-inventory"
  content  = <<EOT
  ${aws_instance.terraform-instance1.public_ip}
  ${aws_instance.terraform-instance2.public_ip}
  ${aws_instance.terraform-instance3.public_ip}
    EOT
}

# Route 53 and sub-domain name setup

resource "aws_route53_zone" "domain-name" {
  name = "abdulbarri.online"
}

resource "aws_route53_zone" "sub-domain-name" {
  name = "terraform-test.abdulbarri.online"

  tags = {
    Environment = "sub-domain-name"
  }
}

resource "aws_route53_record" "record" {
  zone_id = aws_route53_zone.domain-name.zone_id
  name    = "terraform-test.abdulbarri.online"
  type    = "A"

  alias {
    name                   = aws_lb.terraform-load-balancer.dns_name
    zone_id                = aws_lb.terraform-load-balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [
    aws_lb.terraform-load-balancer
  ]
}
