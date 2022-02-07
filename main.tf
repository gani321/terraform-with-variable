provider"aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
resource "aws_vpc" "myvpc" {
  cidr_block       = var.vpc_cidr
    instance_tenancy = "default"
  tags = {
    Name = var.vpc_name
  }
}
resource "aws_subnet" "public_subnets" {
  count = length(var.subnet_cidr)
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = element(var.subnet_cidr, count.index)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = element(var.subnet_name, count.index)
  }
}
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = var.igw_name
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  tags = {
    Name = var.pub_rt_name
  }
}
resource "aws_route_table_association" "public_subnets" {
  count =length(var.subnet_cidr)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "allow_sshhttp" {
  name        = "allow_sshhttp"
  description = "Allow sshhttp inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  ingress {
    description      = "ssh from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "http from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_sshhttp"
  }
}
resource "aws_instance" "myinstance" {
  ami           = var.imagename
  instance_type = var.instance_type
  key_name               = "eee"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.allow_sshhttp.id]
  subnet_id              = aws_subnet.public_subnets.0.id
  #delete_on_termination = true
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = var.instance_name
  }
}

