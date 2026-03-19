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
resource "aws_vpc" "existing" {
  cidr_block = "10.2.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-C-TF"
  }
}






#Public Subnet 1
resource "aws_subnet" "existing_public" {
  vpc_id = aws_vpc.existing.id
  cidr_block = "10.2.1.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true


  tags = {
    name = "${var.project_name}-public-subnet-1"
  }
}

#Public Subnet 2
resource "aws_subnet" "existing_public_2" {
  vpc_id = aws_vpc.existing.id
  cidr_block = "10.2.2.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true


  tags = {
    name = "${var.project_name}-public-subnet-2"
  }

}








# Security Group
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sgTF"
  description = "Security group for ECS app"
  vpc_id      = aws_vpc.existing.id

  # Self-referencing all traffic
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  # Self-referencing port 3000
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    self            = true
  }

  # Port 8000 rules
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Port 80 rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
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



# ECS role
resource "aws_iam_role" "existing_ecs_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.existing_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}




# CloudWatch Log Group 
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# Load Balancer
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

# Target Group
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
    subnets         = [aws_subnet.existing_public.id]
    security_groups = [aws_security_group.app_sg.id]
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
  execution_role_arn       = aws_iam_role.existing_ecs_role.arn  # CHANGED

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
