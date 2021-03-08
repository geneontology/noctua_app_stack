resource "aws_instance" "noctua_app_stack_server" {
  ami                    = "ami-07dd19a7900a1f049"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.noctua_app_stack_sg.id]
  subnet_id = aws_subnet.noctua_app_stack_public_subnet.id
  key_name               = var.key_name
  tags                   = var.tags

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    tags                  = var.tags
    volume_size           = 100
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
      host        = aws_instance.noctua_app_stack_server.public_ip
      type        = "ssh"
      user        = "ubuntu"
      agent       = false
      private_key = file(var.private_key_path)
    }
  }
}
