terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
data "aws_vpc" "existing" {
  id = "vpc-081707759833234e4"
}



#Public Subnet 1
data "aws_subnet" "existing_public" {
    id = "subnet-05a73c3c852dc2951"
}

#Public Subnet 2
data "aws_subnet" "existing_public_2" {
    id = "subnet-0b9ac58d76f700bb6"
}


# Security Group
data "aws_security_group" "TerraformSG" {
id = "sg-0187dc5a4e31521a0"      
}

# ECS role
data "aws_iam_role" "existing_ecs_role" {
  name = "ecsTaskExecutionRole"
}




# CloudWatch Log Group 
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# Load Balancer
resource "aws_lb" "ECS_ALB" {
name               = "ECS-TF-ALB"
internal           = false
load_balancer_type = "application"
security_groups    = [data.aws_security_group.TerraformSG.id]
subnets            = [
    data.aws_subnet.existing_public.id,
    data.aws_subnet.existing_public_2.id
]
}

# Target Group
resource "aws_lb_target_group" "ECS_TG" {
name     = "ECS-TF-TG"
port     = 3000
protocol = "HTTP"
vpc_id   = data.aws_vpc.existing.id
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



# Listener
resource "aws_lb_listener" "ECS_ALB_Listener" {
load_balancer_arn = aws_lb.ECS_ALB.arn
port              = 80
protocol          = "HTTP"
default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ECS_TG.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
name = "${var.project_name}-cluster"
}


# ECS Service
resource "aws_ecs_service" "app" {
name            = "${var.project_name}-service"
cluster         = aws_ecs_cluster.main.id
task_definition = aws_ecs_task_definition.app.arn
desired_count   = 1
launch_type     = "FARGATE"
depends_on = [aws_lb_listener.ECS_ALB_Listener]

network_configuration {
    subnets         = [data.aws_subnet.existing_public.id]
    security_groups = [data.aws_security_group.TerraformSG.id]
    assign_public_ip = true
    }
load_balancer {
    target_group_arn = aws_lb_target_group.ECS_TG.arn
    container_name   = "app"
    container_port   = 3000
  }
}




#Task definition
# Update this section in your task definition:
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.existing_ecs_role.arn  # CHANGED

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
