resource "aws_security_group" "noctua_app_stack_sg" {
  name   = "nocuta-app-stack-sg"
  vpc_id = aws_vpc.noctua_app_stack_vpc.id
  tags   = var.tags

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.noctua_port
    to_port     = var.noctua_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.barista_port
    to_port     = var.barista_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.golr_port
    to_port     = var.golr_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
