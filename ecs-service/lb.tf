resource "aws_lb" "internal_lb" {
  name               = var.branch == "main" ? "rapp-stage-lb" : "dev-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.private_subnet.ids
  security_groups    = [aws_security_group.lb_sg.id]

}

resource "aws_lb_target_group" "ecs_target_group" {
  name     = var.branch == "main" ? "rapp-stage-lb" : "${var.branch}-dev-lb"
  port     = 3000
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"

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

