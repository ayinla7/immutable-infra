variable "ami_id" {
  type    = string
  default = "ami-0735c191cf914754d"
}

variable "public_key_path" {
    type = string
    default = "/devops-tools/jenkins/id_rsa.pub"
}

locals {
  app_name = "jenkins-agent"
}

source "amazon-ebs" "jenkins" {
  ami_name      = "${local.app_name}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  availability_zone = "us-west-2a"
  source_ami    = "${var.ami_id}"
  ssh_username  = "ubuntu"
  iam_instance_profile = "jenkins-instance-profile"
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
  playbook_file = "ansible/jenkins-agent.yaml"
  extra_arguments = [ "--extra-vars", "public_key_path=${var.public_key_path}",  "--scp-extra-args", "'-O'", "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa" ]
  } 
  
  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}
