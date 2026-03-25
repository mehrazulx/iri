# Hello World ECS Application

A simple Node.js web application deployed on AWS ECS using Terraform and GitHub Actions.

## Architecture

- Application: Node.js Express server
- Container: Docker containerized application  
- Infrastructure: AWS ECS Fargate with Application Load Balancer
- Networking: VPC with public/private subnets across 2 AZs
- CI/CD: GitHub Actions with Terraform
cd
## Local Development

Install dependencies:
cd app && npm install

Run locally:
npm start

## Infrastructure
mkdir cd/my-web-app/app
ls -la app/
drwxr-xr-x. 3 ssm-user ssm-user   126 Mar 17 18:45 .
drwxr-xr-x. 6 ssm-user ssm-user   121 Mar 17 18:44 ..
-rw-r--r--. 1 ssm-user ssm-user   142 Mar 17 18:44 Dockerfile #where the docker image sits
-rw-r--r--. 1 ssm-user ssm-user 29326 Mar 17 18:44 package-lock.json
-rw-r--r--. 1 ssm-user ssm-user   236 Mar 17 18:44 package.json  
-rw-r--r--. 1 ssm-user ssm-user   632 Mar 17 18:44 server-local.js #local server
-rw-r--r--. 1 ssm-user ssm-user   383 Mar 17 18:44 server.js
drwxr-xr-x. 2 ssm-user ssm-user    83 Mar 17 18:44 terraform #where all the infrustructure of codes sits

mkdir cd/my-web-app/app/terraform
sh-5.2$ ls -la
total 16
drwxr-xr-x. 2 ssm-user ssm-user   83 Mar 17 18:50 .
drwxr-xr-x. 3 ssm-user ssm-user  126 Mar 17 18:50 ..
-rw-r--r--. 1 ssm-user ssm-user 3429 Mar 17 18:50 main.tf 
-rw-r--r--. 1 ssm-user ssm-user  618 Mar 17 18:50 outputs.tf
-rw-r--r--. 1 ssm-user ssm-user  150 Mar 17 18:50 terraform.tfvars
-rw-r--r--. 1 ssm-user ssm-user  343 Mar 17 18:50 variables.tf
sh-5.2$

