output "cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "alb_arn" {
  value = aws_alb.alb.arn
}

output "alb_dns_name" {
  value = aws_alb.alb.dns_name
}

# output "alb_listener_https_arn" {
#   value = "${aws_alb_listener.listener_https.arn}"
# }

output "alb_listener_http_arn" {
  value = aws_alb_listener.listener_http.arn
}

output "ecs_autoscale_role_arn" {
  value = aws_iam_role.ecs_autoscale_role.arn
}

output "topic_logs_watchers_arn" {
  value = aws_sns_topic.topic_logs_watchers.arn
}

