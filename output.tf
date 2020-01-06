# ${module.moduleIstance.outputModuleVar}
output "alb_dns_name" {
  value = "${module.ecs_cluster.alb_dns_name}"
}