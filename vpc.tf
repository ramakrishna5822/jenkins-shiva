resource "aws_vpc" "test"{
    cidr_block = var.cidr_block
    enable_dns_hostnames = true
    tags = {
        Name = var.vpc_name 
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.test.id
    tags = {
        Name = "${var.vpc_name}-igw"
    }
}

resource "aws_subnet""public-subnets" {
    count = 3
    vpc_id = aws_vpc.test.id
    cidr_block = element(var.public_cidr_blocks,count.index)
    availability_zone = element(var.azs,count.index)
    tags = {
        Name = "${var.vpc_name}-publicsubnets-${count.index+1}"
    }

}

resource "aws_route_table" "public-rt" {
    vpc_id = aws_vpc.test.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "${var.vpc_name}-public-rt"
    }
}


resource "aws_route_table_association" "publicsubnets-association" {
    count = 3
    subnet_id = element(aws_subnet.public-subnets.*.id,count.index)
    route_table_id = aws_route_table.public-rt.id
}


resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.test.id
    name = "${var.vpc_name}-sg"
    description = "Allow inbound traffic"
    tags = {
        Name = "${var.vpc_name}-sg"
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0 
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

 }
resource "aws_instance" "dev" {
    count = 1
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.sg.id]
    subnet_id = element(aws_subnet.public-subnets.*.id,count.index)
    private_ip = element(var.private_ips,count.index)
    associate_public_ip_address = true
    user_data=<<-EOF
                #!/bin/bash
               sudo apt update -y
               sudo apt install openjdk-21-jre-headless -y
               sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install jenkins -y
                EOF
                tags = {
                    Name = "${var.vpc_name}-dev-${count.index+1}"
}
}