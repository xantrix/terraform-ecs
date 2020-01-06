variable "environment" {
  description = "The environment"
}
variable "vpc_id" {
  description = "The VPC id"
}

variable "public_subnet_ids" {
  type        = "list"
  description = "The private subnets to use"
}

variable "security_groups_ids" {
  type        = "list"
  description = "The SGs to use"
}

variable "cert_domain" {
  description = "The https certificate domain"
  default = "*.domain.com"
}

variable "ssl_policy" {
  description = "The ssl_policy"
  default = "ELBSecurityPolicy-FS-2018-06"
}