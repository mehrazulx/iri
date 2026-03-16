# Hello World ECS Application

A simple Node.js web application deployed on AWS ECS using Terraform and GitHub Actions.

## Architecture

- Application: Node.js Express server
- Container: Docker containerized application  
- Infrastructure: AWS ECS Fargate with Application Load Balancer
- Networking: VPC with public/private subnets across 2 AZs
- CI/CD: GitHub Actions with Terraform

## Local Development

Install dependencies:
cd app && npm install

Run locally:
npm start

## Infrastructure

The infrastructure is defined in Terraform and includes:
- VPC with public/private subnets
- Application Load Balancer
- ECS Fargate cluster and service
- ECR repository
- CloudWatch logging

## Deployment

Deployment is automated via GitHub Actions on:
- Manual workflow dispatch
- Push to main branch

## Endpoints

- / - Hello World message
- /health - Health check endpoint
