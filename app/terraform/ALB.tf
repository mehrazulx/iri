# Load Balancer________________________________________________________________________________
resource "aws_lb" "ECS_ALB" {
name               = "ECS-ALB-NEW"
internal           = false
load_balancer_type = "application"
security_groups    = [aws_security_group.app_sg.id]
subnets            = [
    aws_subnet.existing_public.id,
    aws_subnet.existing_public_2.id
]
}