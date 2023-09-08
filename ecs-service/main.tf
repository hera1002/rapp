provider "aws" {
  region = "us-east-1"  # Change to your desired AWS region
  #TODO specify AWS provider version
}

data "aws_vpc" "default" {
  tags = {
    Name = "rapp"  # Replace with your desired subnet tag key-value pair
  }
}

data "aws_subnets" "public_subnet" {
  filter {
    name   = "vpc-id"
    values =  [data.aws_vpc.default.id]
  }

  tags = {
    type = "public"
  }
}

data "aws_subnets" "private_subnet" {
  filter {
    name   = "vpc-id"
    values =  [data.aws_vpc.default.id]
  }

  tags = {
    type = "private"
  }
}

data "aws_ecs_cluster" "rapp" {
  cluster_name = "rapp"
}

data "aws_ecs_cluster" "rapp-dev" {
  cluster_name = "rapp-dev"
}

resource "aws_ecs_task_definition" "my_app" {
  family                   = "r-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu    = "256"  # Specify the CPU units (1 vCPU = 256 CPU units)
  memory = "512"  # Specify the memory in megabyte
  container_definitions = jsonencode([
    {
      name  = "r-app-container"
      image = "${var.image_uri}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "my_app" {
  name            = var.branch == "main" ? "rapp-stge" : "${var.branch}-dev"
  cluster         = var.branch == "main" ? data.aws_ecs_cluster.rapp.id : data.aws_ecs_cluster.rapp-dev.id
  task_definition = aws_ecs_task_definition.my_app.arn
  launch_type     = "FARGATE"
  desired_count   = 4

  network_configuration {
    subnets = data.aws_subnets.private_subnet.ids
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
 load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "r-app-container"  # Replace with your container name
    container_port   = 3000  # Port that your container listens on
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service"
  description = "Allow all ports from 10.0.0.0/8"
  vpc_id      = "vpc-07aeb65db4c5d753f"
  ingress {
    from_port   = 0   # Allow traffic from any port
    to_port     = 65535  # Allow traffic to any port
    protocol    = "tcp"  # Allow TCP traffic
    cidr_blocks = ["10.0.0.0/8"]  # Specify the IP range to allow
  }

  egress {
    from_port   = 0   # Allow traffic from any port
    to_port     = 0  # Allow traffic to any port
    protocol    = "-1"  # Allow all protocols for egress traffic
    cidr_blocks = ["0.0.0.0/0"]  # Allow egress traffic to any destination
  }
}



resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow all ports from 10.0.0.0/8"
  vpc_id      = "vpc-07aeb65db4c5d753f"
  ingress {
    from_port   = 80   # Allow traffic from any port
    to_port     = 80  # Allow traffic to any port
    protocol    = "tcp"  # Allow TCP traffic
    cidr_blocks = ["10.0.0.0/8"]  # Specify the IP range to allow
  }

  egress {
    from_port   = 0   # Allow traffic from any port
    to_port     = 0  # Allow traffic to any port
    protocol    = "-1"  # Allow all protocols for egress traffic
    cidr_blocks = ["0.0.0.0/0"]  # Allow egress traffic to any destination
  }
}


terraform {
  backend "s3" {
    bucket         = "app-r"
    key            = "ecs-servcie.tfstate"
    region         = "us-east-1" # Change to your desired AWS region
    encrypt        = true
    dynamodb_table = "terraform-lock"
    workspace_key_prefix = "tf-state"
  }
}
