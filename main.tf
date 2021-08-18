provider "aws" {
    region = "ap-south-1"
    access_key = var.access
    secret_key = var.secret
}

resource "aws_vpc" "terraform-vpc" {
    cidr_block = "10.158.16.0/24"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    tags= {
        Name = "terraform"
    }
}
terraform {
  backend "s3" {
    bucket = "infoinfo"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}


resource "aws_subnet" "sub-1" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    cidr_block ="10.158.16.0/26"
    map_public_ip_on_launch = "true"
    availability_zone = "ap-south-1a"
    tags= {
       Name = "public"
    }
}

resource "aws_subnet" "sub-2" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    cidr_block ="10.158.16.64/26"
    map_public_ip_on_launch = "true"
    availability_zone = "ap-south-1b"
    tags= {
       Name = "public"
    }
}

resource "aws_subnet" "sub-3" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    cidr_block ="10.158.16.128/26"
    map_public_ip_on_launch = "true"
    availability_zone = "ap-south-1c"
    tags= {
       Name = "public"
    }
}


resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    tags= {
       Name = "internet-gateway"
    }
}

resource "aws_route_table" "rt1" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
    tags ={
       Name = "Default"
    }
}

resource "aws_route_table" "rt2" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
    tags ={
       Name = "Default"
    }
}

resource "aws_route_table" "rt3" {
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }
    tags ={
       Name = "Default"
    }
}


resource "aws_route_table_association" "association-subnet-1" {
     subnet_id = "${aws_subnet.sub-1.id}"
     route_table_id = "${aws_route_table.rt1.id}"
}

resource "aws_route_table_association" "association-subnet-2" {
     subnet_id = "${aws_subnet.sub-2.id}"
     route_table_id = "${aws_route_table.rt2.id}"
}

resource "aws_route_table_association" "association-subnet-3" {
     subnet_id = "${aws_subnet.sub-3.id}"
     route_table_id = "${aws_route_table.rt3.id}"
}



resource "aws_security_group" "websg" {
    name = "security_instance"
    vpc_id = "${aws_vpc.terraform-vpc.id}"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "http"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
 
    }
    ingress {
        description = "ssh"
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
}

resource "aws_instance" "terraform_linux" {
    ami = "ami-0c1a7f89451184c8b"
    instance_type = "t2.micro"
    key_name = "einfo"
    associate_public_ip_address = "true"
    vpc_security_group_ids = ["${aws_security_group.websg.id}"]
    subnet_id = "${aws_subnet.sub-1.id}"
    user_data = <<-EOF
    #!/bin/bash
    sudo su -
    apt-get update
    apt-get install nginx -y
    cd /var
    mkdir /www
    cd /www
    mkdir /html
    cd /html
    echo -e '<html>\n<head>\n<title>Welcome to nginx!</title>\n</head>\n<body bgcolor="white" text=
    "black">\n<center><h1>Hello from server-1</h1></center>\n</body>\n</html>' > /var/www/html/index.html
    systemctl start nginx
    systemctl restart nginx
    chkconfig nginx on
    EOF

    lifecycle {
       create_before_destroy = true
    }

    tags= {
       Name =  "terraform-example2"
    }
}


resource "aws_instance" "terraform_linux_2" {
    ami = "ami-0c1a7f89451184c8b"
    instance_type = "t2.micro"
    key_name = "einfo"
    associate_public_ip_address = "true"
    vpc_security_group_ids = ["${aws_security_group.websg.id}"]
    subnet_id = "${aws_subnet.sub-2.id}"
    user_data = <<-EOF
    #!/bin/bash
    sudo su -
    apt-get update
    apt-get install nginx -y
    cd /var
    mkdir /www
    cd /www
    mkdir /html
    cd /html
    echo -e '<html>\n<head>\n<title>Welcome to nginx!</title>\n</head>\n<body bgcolor="white" text=
    "black">\n<center><h1>Hello from server-2</h1></center>\n</body>\n</html>' > /var/www/html/index.html
    systemctl start nginx
    systemctl restart nginx
    chkconfig nginx on
    EOF

    lifecycle {
       create_before_destroy = true
    }

    tags= {
       Name = "terraform-example2"
    }
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.sub-1.id,aws_subnet.sub-2.id]
  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }  
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-vpc.id
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.terraform_linux.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.terraform_linux_2.id
  port             = 80
}




output "vpc-id" {
    value = "${aws_vpc.terraform-vpc.id}"
}

output "vpc-publicsubnet" {
    value = "${aws_subnet.sub-1.cidr_block}"
}

output "vpc-publicsubnet-id" {
    value = "${aws_subnet.sub-1.id}"
}

output "DNS" {
    value = "${aws_lb.test.dns_name}"
}

output "instance-1" {
    value = "${aws_instance.terraform_linux.id}"
}
output "instance-2" {
    value = "${aws_instance.terraform_linux_2.id}"
}
