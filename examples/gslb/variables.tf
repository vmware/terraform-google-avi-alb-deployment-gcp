variable "project" {
  description = "The project used for the Avi Controller"
  type        = string
}
variable "avi_version" {
  description = "The version of Avi that will be deployed"
  type        = string
}
variable "register_controller" {
  description = "If enabled is set to true the controller will be registered and licensed with Avi Cloud Services. The Long Organization ID (organization_id) can be found from https://console.cloud.vmware.com/csp/gateway/portal/#/organization/info. The jwt_token can be retrieved at https://portal.avipulse.vmware.com/portal/controller/auth/cspctrllogin"
  sensitive   = false
  type        = object({ enabled = bool, jwt_token = string, email = string, organization_id = string })
  default     = { enabled = "false", jwt_token = "", email = "", organization_id = "" }
}
variable "controller_default_password" {
  description = "This is the default password for the Avi controller image and can be found in the image download page."
  type        = string
  sensitive   = true
}
variable "controller_password" {
  description = "The password that will be used authenticating with the Avi Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "service_account_email" {
  description = "This is the service account that will be leveraged by the Avi Controller. If the create-iam variable is true then this module will create the necessary custom roles and bindings for the SA"
  type        = string
}
variable "controller_image_gs_path" {
  description = "The Google Storage path to the GCP Avi Controller tar.gz image file using the bucket/filename syntax"
  type        = string
}
variable "name_prefix_east" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "name_prefix_west" {
  description = "This prefix is appended to the names of the Controller and SEs in Site 2"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed and configured"
  type        = bool
  default     = "false"
}
variable "controller_public_address" {
  description = "This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller."
  type        = bool
  default     = "true"
}
variable "custom_vpc_name" {
  description = "This field can be used to specify an existing VPC for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "custom_subnetwork_east" {
  description = "This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "custom_subnetwork_west" {
  description = "This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}