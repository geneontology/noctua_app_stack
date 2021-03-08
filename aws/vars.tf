variable "tags" {
  type = map
  default = { Name = "testing-noctua-app-stack" }
}

variable "instance_type" {
  default = "t2.large" 
}

variable "key_name" {
  default = "noctua-app-stack-ssh-key"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "ssh server port"
}

variable "noctua_port" {
  type        = number
  default     = 8080
  description = "noctua server port"
}

variable "barista_port" {
  type        = number
  default     = 8090
  description = "barista server port"
}

variable "golr_port" {
  type        = number
  default     = 8983
  description = "golr server port"
}
