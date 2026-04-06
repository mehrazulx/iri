
# Security Group________________________________________________________________________________
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sgTF"
  description = "Security group for ECS app"
  vpc_id      = aws_vpc.existing.id

  
  # Self-referencing port 3000
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
  }



  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 

  # Outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sgTF"
  }
}

