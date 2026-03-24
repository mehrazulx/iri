# Target Group________________________________________________________________________________
resource "aws_lb_target_group" "ECS_TG" {
name     = "ECS-TG"
port     = 3000
protocol = "HTTP"
vpc_id   = aws_vpc.existing.id
target_type ="ip" # required fpr fargate
 health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}



# Listener________________________________________________________________________________
resource "aws_lb_listener" "ECS_ALB_Listener" {
load_balancer_arn = aws_lb.ECS_ALB.arn
port              = 80
protocol          = "HTTP"
default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ECS_TG.arn
  }
}