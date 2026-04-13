provider "aws" {
  region = "eu-central-1" 
}

# 1. Dynamically find the latest Ubuntu 22.04 Image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 2. Network Infrastructure (VPC, Subnet, IGW, Route Table)
resource "aws_vpc" "capstone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Capstone-VPC" }
}

resource "aws_subnet" "capstone_subnet" {
  vpc_id                  = aws_vpc.capstone_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = { Name = "Capstone-Public-Subnet" }
}

resource "aws_internet_gateway" "capstone_igw" {
  vpc_id = aws_vpc.capstone_vpc.id
}

resource "aws_route_table" "capstone_rt" {
  vpc_id = aws_vpc.capstone_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone_igw.id
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "capstone_assoc" {
  subnet_id      = aws_subnet.capstone_subnet.id
  route_table_id = aws_route_table.capstone_rt.id
}

# 3. Security Group
resource "aws_security_group" "capstone_sg" {
  name        = "capstone-security-group"
  vpc_id      = aws_vpc.capstone_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #TODO Restrict this to my IP for better security in production!
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FastAPI Application"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes NodePort for AI API"
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana UI"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus UI"
    from_port   = 30090
    to_port     = 30090
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

# 4. The Capstone Server (c7i-flex.large) with Automated Setup
resource "aws_instance" "capstone_server" {

  root_block_device {
    volume_size = 16 # Upgrades the default 8GB drive to 16GB!
    volume_type = "gp3"
  }

  ami           = data.aws_ami.ubuntu.id
  instance_type = "c7i-flex.large" 
  subnet_id     = aws_subnet.capstone_subnet.id
  vpc_security_group_ids = [aws_security_group.capstone_sg.id]
  key_name      = "capstone-key" # AWS Key Pair for SSH access

  # The "user_data" script installs everything automatically on boot
  user_data = <<-EOF
              #!/bin/bash
              # Update OS
              sudo apt-get update -y
              
              # Install Docker
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
              sudo usermod -aG docker ubuntu
              
              # Install Java (Required for Jenkins)
              sudo apt-get install fontconfig openjdk-17-jre -y
              
              # Install Jenkins (Updated 2026 Key)
              sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install jenkins -y
              
              # Install K3s (Lightweight Kubernetes)
              curl -sfL https://get.k3s.io | sh -
              sudo chmod 644 /etc/rancher/k3s/k3s.yaml
              EOF

  tags = { Name = "Capstone-DevOps-Server" }
}

# 5. Output the Public IP so you don't have to search for it!
output "server_public_ip" {
  value       = aws_instance.capstone_server.public_ip
  description = "Copy this IP to access Jenkins and your API!"
}