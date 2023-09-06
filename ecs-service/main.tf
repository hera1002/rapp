variable "image_tag" {
  default = "main-9a41ea3"
}
variable "image_uri" {
  default = "136629348357.dkr.ecr.us-east-1.amazonaws.com/rapp"
}
variable "branch" {
  default = "main"
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
  family                   = "my-app"
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
      memory        = 512  # Specify the memory value in megabytes
      memory_reservation = 256  # Specify the memory reservation in megabytes
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
    subnets = ["subnet-023c24b71579d4c85"]
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.ecs_target_group.arn
  #   container_name   = "my-container-name"  # Replace with your container name
  #   container_port   = 3000 # Replace with the port your application listens on
  # }
}




# resource "aws_lb" "internal_lb" {
#   name               = "my-internal-lb"
#   internal           = true
#   load_balancer_type = "application"
#   subnets            = data.aws_subnets.private_subnet[0].id
# }

# resource "aws_lb_target_group" "ecs_target_group" {
#   name     = "ecs-target-group"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = data.aws_vpc.default.id
# }

# resource "aws_lb_listener" "ecs_listener" {
#   load_balancer_arn = aws_lb.internal_lb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ecs_target_group.arn
#   }
# }
