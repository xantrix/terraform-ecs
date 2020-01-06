/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-ecs"
}

/*====
Application Load Balancer
======*/

/* security group for ALB */
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS from Anywhere into ALB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_alb" "alb" {
  name            = "${var.environment}-alb"
  subnets         = flatten(["${var.public_subnet_ids}"])
  security_groups = flatten(["${var.security_groups_ids}", "${aws_security_group.alb_sg.id}"])

  tags = {
    Name        = "${var.environment}-alb"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  #redirect to https
  # default_action {
  #   type = "redirect"

  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }

  #fixed default action
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "not found"
      status_code  = "404"
    }
  }

}

# data "aws_acm_certificate" "cert" {
#   domain   = "${var.cert_domain}"
#   statuses = ["ISSUED"]
# }

# resource "aws_alb_listener" "listener_https" {
#   load_balancer_arn = "${aws_alb.alb.arn}"
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "${var.ssl_policy}"
#   //certificate_arn   = "${data.aws_acm_certificate.cert.arn}"
#   //depends_on        = ["aws_alb_target_group.alb_target_group"]

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "not found"
#       status_code  = "404"
#     }
#   }  
# }

resource "aws_sns_topic" "topic_logs_watchers" {
  name = "LogsWatchers"
}