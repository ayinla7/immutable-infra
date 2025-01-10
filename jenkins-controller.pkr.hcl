packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "ami_id" {
  type    = string
  default = "ami-0735c191cf914754d"
}

variable "efs_mount_point" {
  type    = string
  default = ""
}

locals {
  app_name = "jenkins-controller"
}

source "amazon-ebs" "jenkins" {
  ami_name      = "${local.app_name}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  availability_zone = "us-west-2a"
  source_ami    = "${var.ami_id}"
  ssh_username  = "ubuntu"


    # Add these VPC configurations
  vpc_id                      = "vpc-0de14e8fbcbe9410a" # Replace with your VPC ID
  subnet_id                   = "subnet-01033882bf86e7175" # Replace with your subnet ID
  associate_public_ip_address = true
  ssh_interface = "public_ip"

    # Add a temporary security group rule for SSH
  ssh_timeout = "10m"
  ssh_port    = 22

  user_data = <<-EOF
              #!/bin/bash
              echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
              systemctl restart sshd
              EOF




  tags = {
    Env  = "dev"
    Name = "${local.app_name}"
  }
}

build {
  sources = ["source.amazon-ebs.jenkins"]

  provisioner "ansible" {
  playbook_file = "ansible/jenkins-controller.yaml"
  extra_arguments = [ "--extra-vars", "ami-id=${var.ami_id} efs_mount_point=${var.efs_mount_point}", "--scp-extra-args", "'-O'", "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa" ]
  } 
  
  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}
