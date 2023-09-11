# resource "aws_lb" "internal_lb" {
#   name               = var.branch == "main" ? "bbuy-stage-lb" : "dev-lb"
#   internal           = true
#   load_balancer_type = "application"
#   subnets            = data.aws_subnets.private_subnet.ids
#   security_groups    = [aws_security_group.lb_sg.id]
# }


data "aws_lb" "alb" {
  name =  var.branch == "main" ? "bbuy-stage-lb" : "bbuy-dev-lb"
}


resource "aws_lb_target_group" "ecs_target_group" {
  name     = var.branch == "main" ? "bbuy-stage-tg" : "${var.branch}-dev-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}
