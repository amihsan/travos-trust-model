provider "aws" {
  region = "eu-central-1"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"

  lifecycle {
    prevent_destroy = true
  }
}

# Enable S3 Versioning (Required for state rollback)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce Server-Side Encryption (SSE)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access to S3 Bucket
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Terraform Backend Configuration (Applied After First Run)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

# EC2 Instance
resource "aws_instance" "my_ec2" {
  ami           = "ami-0c55b159cbfafe1f0"  # Update to your region's AMI
  instance_type = "t2.micro"
  key_name      = "my-key"  # Ensure the key pair exists

  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = "MyTerraformEC2"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
