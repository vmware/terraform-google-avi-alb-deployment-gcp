output "controllers_west" {
  description = "IP address for the West region controller"
  value       = module.avi_controller_west.controllers
}
output "controllers_east" {
  description = "IP address for the East region controller"
  value       = module.avi_controller_east.controllers
}