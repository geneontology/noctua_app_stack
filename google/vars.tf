variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "noctua_port" {
  description = "noctua server port"
  type        = number
  default     = 8080
}

variable "barista_port" {
  description = "barista server port"
  type        = number
  default     = 8090
}

variable "golr_port" {
  description = "golr server port"
  type        = number
  default     = 8983
}
