variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hello-world-app"
}

variable "container_image" {
  description = "Docker image to run in the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "aws_vpc_endpoint_sevices.this.service_name"
 
}
