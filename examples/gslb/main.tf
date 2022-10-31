terraform {
  required_version = ">= 1.3.0"
  backend "local" {
  }
}
module "avi_controller_east" {
  source = "../.."

  region                      = "us-east1"
  create_networking           = "false"
  custom_vpc_name             = var.custom_vpc_name
  custom_subnetwork_name      = var.custom_subnetwork_east
  create_iam                  = "false"
  avi_version                 = var.avi_version
  controller_public_address   = var.controller_public_address
  service_account_email       = var.service_account_email
  controller_ha               = var.controller_ha
  controller_default_password = var.controller_default_password
  controller_image_gs_path    = var.controller_image_gs_path
  controller_password         = var.controller_password
  name_prefix                 = var.name_prefix_east
  project                     = var.project
  configure_ipam_profile      = "true"
  ipam_networks               = [{ network = "192.168.252.0/24", static_pool = ["192.168.252.10", "192.168.252.100"] }]
  configure_dns_profile       = { enabled = "true", usable_domains = ["avieast.local"] }
  configure_dns_vs            = { enabled = "true", auto_allocate_ip = true, auto_allocate_public_ip = true, vs_ip = "", network = "192.168.252.0/24" }
  configure_gslb              = { enabled = "true", site_name = "East1" }
  register_controller         = var.register_controller
}
module "avi_controller_west" {
  source = "../.."

  region                      = "us-west1"
  create_networking           = "false"
  custom_vpc_name             = var.custom_vpc_name
  custom_subnetwork_name      = var.custom_subnetwork_west
  create_iam                  = "false"
  avi_version                 = var.avi_version
  controller_public_address   = var.controller_public_address
  service_account_email       = var.service_account_email
  controller_ha               = var.controller_ha
  controller_default_password = var.controller_default_password
  controller_image_gs_path    = var.controller_image_gs_path
  controller_password         = var.controller_password
  name_prefix                 = var.name_prefix_west
  project                     = var.project
  configure_ipam_profile      = "true"
  ipam_networks               = [{ network = "192.168.251.0/24", static_pool = ["192.168.251.10", "192.168.251.100"] }]
  configure_dns_profile       = { enabled = "true", usable_domains = ["aviwest.local"] }
  configure_dns_vs            = { enabled = "true", auto_allocate_ip = true, auto_allocate_public_ip = true, vs_ip = "", network = "192.168.251.0/24" }
  configure_gslb              = { enabled = "true", site_name = "West1", domains = ["avigslb.local"], additional_sites = [{ name = "East1", ip_address_list = module.avi_controller_east.controllers[*].private_ip_address }] }
  register_controller         = var.register_controller
}