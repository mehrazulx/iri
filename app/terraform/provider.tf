terraform {
  backend "s3" {
    bucket = "helloworld-tfstate-123"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}
