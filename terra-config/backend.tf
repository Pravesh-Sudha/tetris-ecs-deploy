terraform {
  backend "s3" {
    bucket = "pravesh-tetris-backend"
    key    = "ecs-state-file/terraform.tfstate"
    region = "us-east-1"
  }
}
