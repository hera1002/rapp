variable "image_tag" {}
variable "image_uri" {}
variable "branch" {}

resource "aws_ecs_task_definition" "my_app" {
  family                   = "my-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "r-app-container"
      image = "${var.image_uri}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
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

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
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

resource "aws_ecs_service" "my_app" {
  name            = var.branch == "main" ? "my-app" : "my-app-dev"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.my_subnet.id]
    security_groups = [aws_security_group.my_security_group.id]
  }
}

resource "aws_subnet" "my_subnet" {
  # Define your subnets
}

resource "aws_security_group" "my_security_group" {
  # Define your security group
}
