output "private_key_path" {
  value = var.private_key_path
}

output "noctua_port" {
  value = var.noctua_port
}

output "barista_port" {
  value = var.barista_port
}

output "golr_port" {
  value = var.golr_port
}


output "public_ip" {
  value = aws_instance.noctua_app_stack_server.public_ip
}
