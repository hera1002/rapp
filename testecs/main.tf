provider "aws" {
  region = "us-east-1"  # Change to your desired AWS region
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"  # Change to your desired cluster name
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_roles"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_ecs_task_definition" "my_app" {
  family                   = "my-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn  # Change to your desired task role ARN

  cpu    = "256"  # Specify the CPU units (1 vCPU = 256 CPU units)
  memory = "512"  # Specify the memory in megabytes

  container_definitions = jsonencode([
    {
      name  = "my-app-container"
      image = "nginx:latest"  # Replace with your Docker image URL
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "my_app_service" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_app.arn
  launch_type     = "FARGATE"
  desired_count   = 1  # Number of tasks to run

  network_configuration {
    subnets = ["subnet-023c24b71579d4c85","subnet-063b5dbda7d74086b"]  # Change to your desired subnet IDs
    security_groups = [aws_security_group.my_security_group.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "my-app-container"  # Replace with your container name
    container_port   = 80  # Port that your container listens on
  }
}

resource "aws_security_group" "my_security_group" {
  name        = "allow"
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

resource "aws_lb" "internal_lb" {
  name               = "my-internal-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = ["subnet-023c24b71579d4c85","subnet-063b5dbda7d74086b"]  
   security_groups    = [aws_security_group.my_security_group.id]
  # Replace with your private subnet IDs
}


resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}

resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80  # Port that your containers are listening on
  protocol = "HTTP"
  vpc_id      = "vpc-07aeb65db4c5d753f"
  target_type = "ip"
}