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

# VPC___________________________________________________________________________________________________
resource "aws_vpc" "existing" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-Private"
  }
}






#Private subnet____________________________________________________________________________________________
resource "aws_subnet" "existing_private" {
  vpc_id = aws_vpc.existing.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = false


  tags = {
    name = "Private-subnet-1"
  }
}

resource "aws_subnet" "existing_public" {
  vpc_id = aws_vpc.existing.id
  cidr_block = "10.1.0.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true


  tags = {
    name = "Public-subnet-2"
  }
}



# route table______________________________________________________________________________________
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.existing.id

  tags = {
    Name = "RT2"
  }
}

#public RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.existing.id

  tags = {
    Name = "publicRT"
  }
}



# Associate private subnet with  route table________________________________________________________________________________
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.existing_private.id
  route_table_id = aws_route_table.private.id
}





#asssociate publci subnet with route table------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.existing_public.id
  route_table_id = aws_route_table.public.id
}











#create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.existing.id

  tags = {
    Name = "VPC-IGW"
  }
}

#route IGW with public Route table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}







#create NAT GW
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.existing_public.id

  tags = {
    Name = "NAT-Gateway"
  }
}




# Route to local via NAT________________________________________________________________________________
resource "aws_route" "NAT_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}




#create endpoint service_______________________________________________________________________________

resource "aws_vpc_endpoint_service" "Endservice" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.ECS_NLB.arn]

  tags = {
    Name = "MyPrivateLinkService"
  }
}



#create endpoint PrivateLink___________________________________________________________________________
resource "aws_vpc_endpoint" "Privatelink" {
  vpc_id            = aws_vpc.existing.id
  service_name      = aws_vpc_endpoint_service.Endservice.service_name
  vpc_endpoint_type = "Interface"

  subnet_ids         = [aws_subnet.existing_private.id]
  security_group_ids = [aws_security_group.app_sg.id]
  private_dns_enabled = false

  depends_on = [aws_vpc_endpoint_service.Endservice]
}













# Security Group________________________________________________________________________________
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sgTF"
  description = "Security group for ECS app"
  vpc_id      = aws_vpc.existing.id

  # Inbound Rules
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
    cidr_blocks = ["10.1.0.0/16"]
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





# Load Balancer________________________________________________________________________________
resource "aws_lb" "ECS_NLB" {
name               = "ECS-NLB"
internal           = true
load_balancer_type = "network"
subnets            = [aws_subnet.existing_private.id]
}



# Target Group________________________________________________________________________________
resource "aws_lb_target_group" "ECS_TG" {
name     = "ECS-TG"
port     = 3000
protocol = "TCP"
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
resource "aws_lb_listener" "ECS_NLB_Listener" {
load_balancer_arn = aws_lb.ECS_NLB.arn
port              = 80
protocol          = "TCP"
default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ECS_TG.arn
  }
}

# ECS Cluster________________________________________________________________________________
resource "aws_ecs_cluster" "main" {
name = "${var.project_name}-cluster"
}


# ECS Service________________________________________________________________________________
resource "aws_ecs_service" "app" {
name            = "${var.project_name}-service"
cluster         = aws_ecs_cluster.main.id
task_definition = aws_ecs_task_definition.app.arn
desired_count   = 1
launch_type     = "FARGATE"
depends_on = [aws_lb_listener.ECS_NLB_Listener]

network_configuration {
    subnets         = [aws_subnet.existing_private.id]
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = false
    }
load_balancer {
    target_group_arn = aws_lb_target_group.ECS_TG.arn
    container_name   = "app"
    container_port   = 3000
  }
}



























# ECS role________________________________________________________________________________
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



# CloudWatch Log Group ________________________________________________________________________________
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

#Task definition________________________________________________________________________________
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
