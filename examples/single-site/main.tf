terraform {
  required_version = ">= 1.3.0"
  backend "local" {
  }
}
module "avi_controller_gcp" {
  source = "../.."

  region                      = var.region
  project                     = var.project
  create_networking           = var.create_networking
  create_iam                  = var.create_iam
  controller_default_password = var.controller_default_password
  avi_version                 = var.avi_version
  service_account_email       = var.service_account_email
  controller_image_gs_path    = var.controller_image_gs_path
  controller_password         = var.controller_password
  name_prefix                 = var.name_prefix
  controller_ha               = var.controller_ha
  controller_public_address   = var.controller_public_address
  configure_ipam_profile      = var.configure_ipam_profile
  configure_dns_profile       = var.configure_dns_profile
  configure_dns_vs            = var.configure_dns_vs
  register_controller         = var.register_controller
}
