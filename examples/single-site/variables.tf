variable "region" {
  description = "The Region that the Avi controller and SEs will be deployed to"
  type        = string
}
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
variable "name_prefix" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "create_networking" {
  description = "This variable controls the VPC and subnet creation for the Avi Controller. When set to false the custom_vpc_name and custom_subnetwork_name must be set."
  type        = bool
  default     = "true"
}
variable "create_iam" {
  description = "Create IAM Roles and Role Bindings necessary for the Avi GCP Full Access Cloud. If not set the Roles and permissions in this document must be associated with the controller service account - https://Avinetworks.com/docs/latest/gcp-full-access-roles-and-permissions/"
  type        = bool
  default     = "false"
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
variable "configure_ipam_profile" {
  description = "Configure Avi IPAM Profile for Virtual Service Address Allocation. If set to true the virtualservice_network variable must also be set"
  type        = bool
  default     = "false"
}
variable "ipam_networks" {
  description = "This variable configures the IPAM network(s). Example: [{ network = \"192.168.1.0/24\" , static_pool = [\"192.168.1.10\",\"192.168.1.30\"]}]"
  type        = list(object({ network = string, static_pool = list(string) }))
  default     = null
}
variable "configure_dns_profile" {
  description = "Configure Avi DNS Profile for DNS Record Creation for Virtual Services. If set to true the dns_service_domain variable must also be set"
  type        = bool
  default     = "false"
}
variable "dns_service_domain" {
  description = "The DNS Domain that will be available for Virtual Services. Avi will be the Authorative Nameserver for this domain and NS records may need to be created pointing to the Avi Service Engine addresses. An example is demo.Avi.com"
  type        = string
  default     = ""
}
variable "configure_dns_vs" {
  description = "Create DNS Virtual Service. The configure_dns_profile and configure_ipam_profile variables must be set to true and their associated configuration variables must also be set"
  type        = bool
  default     = "false"
}
variable "dns_vs_settings" {
  description = "The DNS Virtual Service settings. With the auto_allocate_ip option is set to \"true\" the VS IP address will be allocated via an IPAM profile. Example:{ auto_allocate_ip = \"true\", auto_allocate_public_ip = \"true\", vs_ip = \"\", network_name = \"network-192.168.20.0/24\", network = \"192.168.20.0/24\" }"
  type        = object({ auto_allocate_ip = bool, auto_allocate_public_ip = bool, vs_ip = string, network = string })
  default     = null
}