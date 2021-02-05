//resource "google_compute_network" "default" {
//  name = "test-network"
//}

resource "google_compute_firewall" "default" {
  name    = "noctua-ports"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [22, var.noctua_port, var.barista_port, var.golr_port]
  }
}

// A single Compute Engine instance
resource "google_compute_instance" "default" {
 name         = "noctua-app-stack"
 // machine_type = "f1-micro"
 machine_type = "e2-standard-4"
 zone         = "us-west1-a"

 boot_disk {
   initialize_params {
     // image = "debian-cloud/debian-9"
     image = "ubuntu-os-cloud/ubuntu-2004-lts"
     size = "100"
   }
 }

 network_interface {
   network = "default"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }

 metadata = {
   ssh-keys = "ubuntu:${file(var.public_key_path)}"
 }

 provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com -o /tmp/get-docker.sh",
      "sudo sh /tmp/get-docker.sh",
      "sudo usermod -aG docker ubuntu",
      "sudo apt-get install -y docker-compose",
      "curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py",
      "sudo python3 /tmp/get-pip.py",
      "sudo pip3 install docker==4.3.1",
    ] 
    
    connection {
      type = "ssh"
      host = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
      user = "ubuntu"
      agent = false
      private_key = file(var.private_key_path)
    } 
 } 
}
