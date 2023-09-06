variable "image_tag" {
  default = ""
}
variable "image_uri" {
  default = "136629348357.dkr.ecr.us-east-1.amazonaws.com/rapp"
}
variable "branch" {
  default = "main"
}




data "aws_vpc" "default" {
  vpc_id = data.aws_vpc.standardvpc.id  # Reference the VPC data source
  tags = {
    Environment = "dev"  # Replace with your desired subnet tag key-value pair
  }
}


data "aws_subnet" "private_subnet" {
  vpc_id = data.aws_vpc.default.id  # Reference the VPC data source

  tags = {
    type = "private"  # Replace with your desired subnet tag key-value pair
  }
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.default.id  # Reference the VPC data source

  tags = {
    type = "public"  # Replace with your desired subnet tag key-value pair
  }
}

data "aws_ecs_cluster" "rapp" {
  name = "rapp"
}


data "aws_ecs_cluster" "rapp-dev" {
  name = "rapp-dev"
}


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
  name            = var.branch == "main" ? "rapp-prod" : "${var.branch}+dev"
  cluster         = var.branch == "main" ? data.aws_ecs_cluster.rapp.id : data.aws_ecs_cluster.rapp-dev.id
  task_definition = aws_ecs_task_definition.my_app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [data.aws_subnet.private_subnet[*].id ]
    security_groups = [aws_security_group.my_security_group.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "my-container-name"  # Replace with your container name
    container_port   = 80  # Replace with the port your application listens on
  }
}



resource "aws_security_group" "my_security_group" {
  # Define your security group
}


resource "aws_lb" "internal_lb" {
  name               = "my-internal-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnet.private_subnet[*].id
}

resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
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
