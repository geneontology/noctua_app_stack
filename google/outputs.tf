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
 value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}
