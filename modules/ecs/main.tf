/*====
Cloudwatch Log Group
======*/
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.environment}/${var.name}"
  retention_in_days = 3

  tags = {
    Environment = var.environment
    Application = var.name
  }
}

resource "aws_cloudwatch_log_metric_filter" "log_error" {
  name           = "ERROR"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.log_group.name

  metric_transformation {
    name          = "Error"
    namespace     = "${var.environment}/${var.name}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_errors_high" {
  alarm_name          = "${var.environment}_${var.name}_errors_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "6"
  metric_name         = "Error"
  namespace           = "${var.environment}/${var.name}"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  treat_missing_data  = "notBreaching" //default:missing notBreaching(good) breaching(bad), ignore(maintain alarm state)

  alarm_actions = [var.topic_logs_watchers_arn]
  ok_actions    = [var.topic_logs_watchers_arn]
}

/*====
ECS task definitions
======*/

data "template_file" "task_template" {
  template = file("${path.module}/tasks/${var.task_template}")

  vars = {
    name        = var.name
    appname     = var.appname
    environment = var.environment
    image       = "${var.image}:${var.image_tag}"
    log_group   = aws_cloudwatch_log_group.log_group.name
    region      = var.region
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.environment}_${var.name}"
  container_definitions    = data.template_file.task_template.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.execution_role_arn
}

/*====
ALB tg and rule
======*/

resource "aws_alb_target_group" "tg" {
  name     = "${var.environment}-${var.name}"
  port     = var.port
  protocol = "HTTP"

  #instance(network bridge), ip(awsvpc), lambda. 
  target_type = "ip"

  #Required when target_type is instance or ip. Does not apply when target_type is lambda.
  vpc_id               = var.vpc_id
  #slow_start           = 600
  deregistration_delay = 10

  # stickiness {
  #   type = "lb_cookie"
  # }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"

    # Defaults to traffic-port above
    // port = "${var.port}" 
    matcher             = "200"
    unhealthy_threshold = 10
  }

  depends_on = [var.tg_depends_on]
}

resource "aws_alb_listener_rule" "rule" {
  listener_arn = var.alb_listener_http_arn
  priority     = var.alb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["*.amazonaws.com"]
    }
  }

  depends_on = [aws_alb_target_group.tg]
}

/*====
ECS service
======*/

/* Security Group for ECS */
resource "aws_security_group" "ecs_service_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-${var.name}"
  description = "Allow egress from container"

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow tcp traffic to container port.
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.name}"
    Environment = var.environment
  }
}

/* Simply specify the family to find the latest ACTIVE revision in that family */
data "aws_ecs_task_definition" "task" {
  task_definition = aws_ecs_task_definition.task.family
  depends_on      = [aws_ecs_task_definition.task]
}

resource "aws_ecs_service" "ecs_service" {
  name = "${var.environment}-${var.name}"
  task_definition = "${aws_ecs_task_definition.task.family}:${max(
    aws_ecs_task_definition.task.revision,
    data.aws_ecs_task_definition.task.revision,
  )}"
  desired_count = var.desired_count
  launch_type   = "FARGATE"
  cluster       = var.cluster_id
  depends_on    = [aws_alb_target_group.tg]

  network_configuration {
    security_groups = flatten([var.security_groups_ids, aws_security_group.ecs_service_sg.id])
    subnets         = var.private_subnets_ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.tg.arn
    container_name   = var.name
    container_port   = var.port
  }
}

/*====
Auto Scaling for ECS
======*/

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.ecs_autoscale_role_arn
  min_capacity       = var.desired_count
  max_capacity       = var.autoscale_max
}

resource "aws_appautoscaling_policy" "up" {
  name               = "${var.environment}_${var.name}_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "down" {
  name               = "${var.environment}_${var.name}_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60        //seconds, after a scaling activity completes and before the next scaling activity can start.
    metric_aggregation_type = "Maximum" // Minimum, Maximum, Average

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1 // A positive value scales up. A negative value scales down.
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# /* metric used for auto scale */
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.environment}_${var.name}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120" //original:300=5m 180=3m 120=2m
  statistic           = "Maximum"
  threshold           = "90" //original:85%

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn, var.topic_logs_watchers_arn]
  ok_actions    = [aws_appautoscaling_policy.down.arn, var.topic_logs_watchers_arn]
}

