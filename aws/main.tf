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
}

resource "aws_instance" "noctua_app_stack_server2" {
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
}
