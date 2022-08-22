variable "tags" {
  type = map
  default = { Name = "testing-noctua-app-stack" }
}

variable "instance_type" {
  default = "t2.large"
}

variable "disk_size" {
  default = 100
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "open_ports" {
  type = list 
  default = [22, 8090, 8080, 8983]
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = [ "~/.aws/credentials" ]
  profile = "default"
}

module "base" {
  source = "git::https://github.com/geneontology/devops-aws-go-instance.git?ref=V2.0"
  instance_type = var.instance_type
  public_key_path = var.public_key_path
  tags = var.tags
  open_ports = var.open_ports
  disk_size = var.disk_size
}

output "public_ip" {
   value                  = module.base.public_ip
}
