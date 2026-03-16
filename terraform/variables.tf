variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name of the project"
  default     = "hello-world-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  default     = "terraform/exercise"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 2
}
