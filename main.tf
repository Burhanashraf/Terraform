provider "aws" {
  region = "eu-west-2"
}

# 1.vpc-prod-eas-uk-001
resource "aws_vpc" "vpc-prod-eas-uk-001" {
  cidr_block       = "11.244.254.0/24"
  instance_tenancy = "default"


  tags = {
    Name        = "vpc-prod-eas-uk-001"
    Environment = "App/Database"
    region      = "eu-west-2"
  }
}
#Subnet
resource "aws_subnet" "prod-eas-uk-private-001-subnet" {
  vpc_id            = aws_vpc.vpc-prod-eas-uk-001.id
  cidr_block        = "11.244.254.0/26" #"var.cidr_block"
  availability_zone = "eu-west-2c"

  tags = {
    Name = "prod-eas-uk-private-001-subnet"
    Type = "Private"

  }
}
resource "aws_subnet" "prod-eas-uk-public-001-subnet" {
  vpc_id            = aws_vpc.vpc-prod-eas-uk-001.id
  cidr_block        = "11.244.254.224/27"
  availability_zone = "eu-west-2c"


  tags = {
    Name = "prod-eas-uk-public-001-subnet"
    Type = "Public"
  }
}

# NETWORK ACCESS CONTROL LIST 
resource "aws_network_acl" "vpc-prod-eas-uk-001" {
  vpc_id = aws_vpc.vpc-prod-eas-uk-001.id

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1" # "all"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "prod-eas-uk-001-nacl"
  }
}

# so subnet association is getting failed
# Error: Reference to undeclared resource
│
│   on vpc.tf line 67, in resource "aws_network_acl_association" "prod-eas-uk-public-001-subnet":
│   67:   subnet_id      = prod-eas-uk-public-001-subnet.id
│
│ A managed resource "prod-eas-uk-public-001-subnet" "id" has not been declared in the root module.
resource "aws_network_acl_association" "prod-eas-uk-public-001-subnet" {
  subnet_id      = prod-eas-uk-public-001-subnet.id
  network_acl_id = aws_network_acl.vpc-prod-eas-uk-001-nacl.id
}
resource "aws_network_acl_association" "prod-eas-uk-private-001-subnet" {
  subnet_id      = prod-eas-uk-private-001-subnet.id
  network_acl_id = aws_network_acl.vpc-prod-eas-uk-001-nacl.id
}

# Security Groups =default
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc-prod-eas-uk-001.id # Replace with your VPC ID

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "default"
  }
}


#security grpoups prod_mysql
resource "aws_security_group" "prod_mysql" {
  name        = "prod_mysql"
  description = "prod_mysql"
  vpc_id      = aws_vpc.vpc-prod-eas-uk-001.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "prod_mysql"
  }
}
#SG=prod_ssh
resource "aws_security_group" "prod_ssh" {
  name        = "prod_ssh"
  description = "prod_ssh"
  vpc_id      = aws_vpc.vpc-prod-eas-uk-001.id

  ingress {
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
    Name = "prod_ssh"
  }
}
#SG=ssh_https
resource "aws_security_group" "ssh_https" {
  name        = "ssh_https"
  description = "ssh_https"
  vpc_id      = aws_vpc.vpc-prod-eas-uk-001.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "ssh_https"
  }
}
#SG=prod_https
resource "aws_security_group" "prod_https" {
  name        = "prod_https"
  description = "prod_https"
  vpc_id      = aws_vpc.vpc-prod-eas-uk-001.id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "prod_https"
  }
}
/*#key pair
resource "aws_key_pair" "prod_us_linux" {
  key_name   = "prod_us_linux"                        # Replace with your desired key pair name
  public_key = aws_key_pair.prod_us_linux # Use the automatically generated public key
}
*/
# ami for ubuntu= ami-0e5f882be1900e43b
resource "aws_instance" "prod-eas-uk-mysql" {
  ami           = "ami-0e5f882be1900e43b"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.prod-eas-uk-private-001-subnet.id
  vpc_security_group_ids = [
    aws_security_group.prod_mysql.id,
    aws_security_group.prod_ssh.id,
  ]

  associate_public_ip_address = false

  tags = {
    Name = "prod-eas-uk-mysql"
  }
}

#S3 Bucket
resource "aws_s3_bucket" "vpc-prod-eas-uk-001-sftp" {
  bucket = "vpc-prod-eas-uk-001-sftp" # Replace with your desired unique bucket name
  acl    = "private"                  # ACLs are disabled

 
  versioning {
    enabled = true # Bucket versioning is enabled
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256" # Server-side encryption with Amazon S3 managed keys (SSE-S3)
      }
    }
  }
}
