data "aws_vpc" "default" {
  tags = {
    Name = "bbuy-vpc"  # Replace with your desired subnet tag key-value pair
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

data "aws_ecs_cluster" "bbuy" {
  cluster_name = "bbuy"
}

data "aws_ecs_cluster" "bbuy-dev" {
  cluster_name = "bbuy-dev"
}

data "aws_iam_role" "existing_ecs_task_role" {
  name = "ecs_task_role"
}
data "aws_iam_role" "existing_ecs_execution_role" {
  name = "ecs_execution_role"
}
resource "aws_ecs_task_definition" "bbuy_app" {
  family                   = "bbuy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.existing_ecs_execution_role.arn
  task_role_arn            = data.aws_iam_role.existing_ecs_task_role.arn
  cpu    = "256"  # Specify the CPU units (1 vCPU = 256 CPU units)
  memory = "512"  # Specify the memory in megabyte
  container_definitions = jsonencode([
    {
      name  = "bbuy"
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
  name            = var.branch == "main" ? "bbuy-stage" : "${var.branch}-dev"
  cluster         = var.branch == "main" ? data.aws_ecs_cluster.bbuy.id : data.aws_ecs_cluster.bbuy-dev.id
  task_definition = aws_ecs_task_definition.bbuy_app.arn
  launch_type     = "FARGATE"
  desired_count   = 4

  network_configuration {
    subnets = data.aws_subnets.private_subnet.ids
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
 load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "bbuy"  # Replace with your container name
    container_port   = 3000  # Port that your container listens on
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service"
  description = "Allow all ports from 10.0.0.0/8"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 0   # Allow traffic from any port
    to_port     = 65535  # Allow traffic to any port
    protocol    = "tcp"  # Allow TCP traffic
    cidr_blocks = ["172.17.0.0/16"]  # Specify the IP range to allow
  }
    ingress {
    from_port   = 0   # Allow traffic from any port
    to_port     = 65535  # Allow traffic to any port
    protocol    = "tcp"  # Allow TCP traffic
    cidr_blocks = ["172.18.0.0/16"]  # Specify the IP range to allow
  }
  egress {
    from_port   = 0   # Allow traffic from any port
    to_port     = 0  # Allow traffic to any port
    protocol    = "-1"  # Allow all protocols for egress traffic
    cidr_blocks = ["0.0.0.0/0"]  # Allow egress traffic to any destination
  }
}
