provider "aws" {
  region = "eu-west-2"
}

#create vpc
resource "aws_vpc" "kaka-vpc" {
   cidr_block ="10.0.0.0/16"
   enable_dns_hostnames = "true"
   tags ={
    Name = "kaka-vpc"
   }
}   

#create internet gateway 
resource "aws_internet_gateway" "kaka-internet-gateway" {
    vpc_id =  aws_vpc.kaka-vpc.id
    tags = {
      Name = "kaka-internet-gateway"
    }
}

#create route tables for internet gateway
resource "aws_route_table" "kaka-route-table-public" {
  vpc_id = aws_vpc.kaka-vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.kaka-internet-gateway.id
  }
tags = {
  Name = "kaka-route-table-public"
}
}

# Associate public subnet 1 with public route table
resource "aws_route_table_association" "kaka-public-subnet1-association" {
  subnet_id      = aws_subnet.kaka-public-subnet1.id
  route_table_id = aws_route_table.kaka-route-table-public.id
}

# Associate public subnet 2 with public route table
resource "aws_route_table_association" "kaka-public-subnet2-association" {
  subnet_id      = aws_subnet.kaka-public-subnet2.id
  route_table_id = aws_route_table.kaka-route-table-public.id
}

#create public subnet-1
resource "aws_subnet" "kaka-public-subnet1" {
  vpc_id                  = aws_vpc.kaka-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"
  tags = {
    Name = "kaka-public-subnet1"
  }
}

# Create Public Subnet-2
resource "aws_subnet" "kaka-public-subnet2" {
  vpc_id                  = aws_vpc.kaka-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2b"
  tags = {
    Name = "kaka-public-subnet2"
  }
}

#create network acl
resource "aws_network_acl" "kaka-network_acl" {
  vpc_id     = aws_vpc.kaka-vpc.id
  subnet_ids = [aws_subnet.kaka-public-subnet1.id, aws_subnet.kaka-public-subnet2.id]

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
resource "aws_security_group" "kaka-load_balancer_sg" {
  name        = "kaka-load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.kaka-vpc.id 
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
resource "aws_security_group" "kaka-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.kaka-vpc.id 
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.kaka-load_balancer_sg.id]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.kaka-load_balancer_sg.id]
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
    Name = "kaka-security-grp-rule"
  }
}

#create instance 1
resource "aws_instance" "kaka-1" {
  ami             = "ami-01b8d743224353ffe"
  instance_type   = "t2.micro"
  key_name        = "terraform-key"
  security_groups = [aws_security_group.kaka-security-grp-rule.id]
  subnet_id       = aws_subnet.kaka-public-subnet1.id
  availability_zone = "eu-west-2a" 
  
   tags = {
    Name   = "kaka-1"
    source = "terraform"
  }

}# creating instance 2 
resource "aws_instance" "kaka-2" {
  ami             = "ami-01b8d743224353ffe"
  instance_type   = "t2.micro"
  key_name        = "terraform-key"
  security_groups = [aws_security_group.kaka-security-grp-rule.id]
  subnet_id       = aws_subnet.kaka-public-subnet2.id
  availability_zone = "eu-west-2b" 
  
   tags = {
    Name   = "kaka-2"
    source = "terraform"
  }
}# creating instance 3
resource "aws_instance" "kaka-3" {
  ami             = "ami-01b8d743224353ffe"
  instance_type   = "t2.micro"
  key_name        = "terraform-key"
  security_groups = [aws_security_group.kaka-security-grp-rule.id]
  subnet_id       = aws_subnet.kaka-public-subnet1.id
  availability_zone = "eu-west-2a"

  tags = {
    Name   = "kaka-3"
    source = "terraform"
  }
}

#create file to store ip addresses of my instances
resource "local_file" "ip_address" {
  filename = "/home/kaka/Desktop/terraformstudy/terraform_project/host-inventory"
  content = <<EOT
  ubuntu@${aws_instance.kaka-1.public_ip}
  ubuntu@${aws_instance.kaka-2.public_ip}
  ubuntu@${aws_instance.kaka-3.public_ip}
    EOT
 }

#create an application load balancer
resource "aws_lb" "kaka-load-balancer" {
  name               = "kaka-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kaka-load_balancer_sg.id]
  subnets            = [aws_subnet.kaka-public-subnet1.id, aws_subnet.kaka-public-subnet2.id]
  
#enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.kaka-1, aws_instance.kaka-2, aws_instance.kaka-3]
}

# Create the target group
resource "aws_lb_target_group" "kaka-target-group" {
  name     = "kaka-target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.kaka-vpc.id 
  
health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

#create the listener
resource "aws_lb_listener" "kaka-listener" {
  load_balancer_arn = aws_lb.kaka-load-balancer.arn
  port              = "80"
  protocol          = "HTTP" 
default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kaka-target-group.arn
  }
}

# Create the listener rule
resource "aws_lb_listener_rule" "kaka-listener-rule" {
  listener_arn = aws_lb_listener.kaka-listener.arn
priority     = 1 
   action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kaka-target-group.arn
  } 
condition {
    path_pattern {
      values = ["/"]
    }
  }
}

#attach target group to load balancer
resource "aws_lb_target_group_attachment" "kaka-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.kaka-target-group.arn
  target_id        = aws_instance.kaka-1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "kaka-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.kaka-target-group.arn
  target_id        = aws_instance.kaka-2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "kaka-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.kaka-target-group.arn
  target_id        = aws_instance.kaka-3.id
  port             = 80 
}


  provisioner "local-exec" {
    command = "ansible-playbook -i host-inventory ansible.yml"
  }



