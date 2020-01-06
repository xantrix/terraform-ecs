variable "environment" {
  description = "The environment"
}

variable "region" {
  description = "The region"
}

variable "name" {
  description = "name of the service"
}
variable "appname" {
  description = "appname of the service"
}

variable "zone_domain" {
  description = "zone_domain"
  default = ""
}
variable "app_subdomain" {
  description = "app_subdomain"
  default = ""
}

variable "alb_dns_name" {
  description = "the alb_dns_name"
}

variable "alb_listener_http_arn" {
  description = "the alb_listener_http_arn"
}

variable "alb_rule_priority" {
  description = "the alb_rule_priority"
}

// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
variable "cpu" {
  description = "cpu of the service"
}
variable "memory" {
  description = "memory of the service"
}

variable "port" {
  description = "port of the service"
}

variable "desired_count" {
  description = "the desired_count"
}
variable "autoscale_max" {
  description = "the autoscale_max"
}

variable "image" {
  description = "image url service without tag"
}
variable "image_tag" {
  description = "tag of the image service"
}

variable "task_template" {
  description = "task_template of the service"
}

variable "cluster_id" {
  description = "the cluster id"
}
variable "cluster_name" {
  description = "the cluster name"
}

variable "execution_role_arn" {
  description = "the execution_role_arn"
}

variable "task_role_arn" {
  description = "the task_role_arn"
}

variable "ecs_autoscale_role_arn" {
  description = "the ecs_autoscale_role_arn"
}

variable "topic_logs_watchers_arn" {
  description = "the topic_logs_watchers_arn"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "availability_zones" {
  type        = "list"
  description = "The azs to use"
}

variable "security_groups_ids" {
  type        = "list"
  description = "The SGs to use"
}

variable "private_subnets_ids" {
  type        = "list"
  description = "The private subnets to use"
}

