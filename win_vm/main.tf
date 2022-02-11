terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74.1"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "winServer" {
  ami           = "ami-0aad84f764a2bd39a"
  instance_type = "t2.micro"
  key_name = "rhel72_splk"
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  get_password_data = true

  tags = {
    Name   = "o11yWinServer"
    Server = "win-server"
  }
}

resource "aws_security_group" "allow_rdp" {
  name        = "allow_rdp"
  description = "Allow RDP inbound traffic"

  ingress {
    description      = "RDP from VPC"
    from_port        = 3389
    to_port          = 3389
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
    Name = "allow_rdp"
  }
}

resource "null_resource" "pwd" {
  count = 1

  triggers = {
    password = "${rsadecrypt(aws_instance.winServer.*.password_data[count.index], file("~/Documents/aws/rhel72_splk.pem"))}"
  }
}

output "admin_pwd" {
  value = "${null_resource.pwd.*.triggers.password}"
} 

output "instance_public_ip" {
  value = aws_instance.winServer.public_ip
}