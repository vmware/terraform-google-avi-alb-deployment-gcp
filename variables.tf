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
variable "avi_upgrade" {
  description = "This variable determines if a patch upgrade is performed after install. The enabled key should be set to true and the url from the Avi Cloud Services portal for the should be set for the upgrade_file_uri key. Valid upgrade_type values are patch or system"
  sensitive   = false
  type        = object({ enabled = bool, upgrade_type = string, upgrade_file_uri = string })
  default     = { enabled = "false", upgrade_type = "patch", upgrade_file_uri = "" }
}
variable "controller_size" {
  description = "This value determines the number of vCPUs and memory allocated for the Avi Controller. Possible values are small, medium, or large."
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.controller_size)
    error_message = "Acceptable values are small, medium, or large."
  }
}
variable "configure_controller" {
  description = "Configure the Avi Controller via Ansible after controller deployment. If set to false all configuration must be done manually with the desired config. The avi-controller-gcp-all-in-one-play.yml Ansible play will still be generated and copied to the first controller in the cluster"
  type        = bool
  default     = "true"
}
variable "configure_ipam_profile" {
  description = "Configure Avi IPAM Profile for Virtual Service Address Allocation. Example: { enabled = \"true\", networks = [{ network = \"192.168.1.0/24\" , static_pool = [\"192.168.1.10\",\"192.168.1.30\"]}] }"
  type = object({
    enabled  = bool,
    networks = list(object({ network = string, static_pool = list(string) }))
  })
  default = { enabled = "false", networks = [{ network = "", static_pool = [""] }] }
}
variable "configure_dns_profile" {
  description = "Configure a DNS Profile for DNS Record Creation for Virtual Services. The usable_domains is a list of domains that Avi will be the Authoritative Nameserver for and NS records may need to be created pointing to the Avi Service Engine addresses. Supported profiles for the type parameter are AWS or AVI"
  type = object({
    enabled        = bool,
    type           = optional(string, "AVI"),
    usable_domains = list(string),
    ttl            = optional(string, "30"),
    aws_profile    = optional(object({ iam_assume_role = string, region = string, vpc_id = string, access_key_id = string, secret_access_key = string }))
  })
  default = { enabled = false, type = "AVI", usable_domains = [] }
  validation {
    condition     = contains(["AWS", "AVI"], var.configure_dns_profile.type)
    error_message = "Supported DNS Profile types are 'AWS' or 'AVI'"
  }
}
variable "configure_dns_vs" {
  description = "Create Avi DNS Virtual Service. The subnet_name parameter must be an existing AWS Subnet. If the allocate_public_ip parameter is set to true a EIP will be allocated for the VS. The VS IP address will automatically be allocated via the AWS IPAM"
  type = object({
    enabled            = bool,
    allocate_public_ip = optional(bool, false),
    network            = string,
    auto_allocate_ip   = optional(bool, true),
    vs_ip              = optional(string)
  })
  default = { enabled = "false", network = "" }
}
variable "configure_gslb" {
  description = "Configures GSLB. In addition the configure_dns_vs variable must also be set for GSLB to be configured. See the GSLB Deployment README section for more information."
  type = object({
    enabled          = bool,
    leader           = optional(bool, false),
    site_name        = string,
    domains          = optional(list(string)),
    create_se_group  = optional(bool, true),
    se_size          = optional(list(string), ["2", "8", "30"]),
    additional_sites = optional(list(object({ name = string, ip_address_list = list(string) })))
  })
  default = { enabled = "false", site_name = "", domains = [""] }
}
variable "name_prefix" {
  description = "This prefix is appended to the names of the Controller and SEs"
  type        = string
}
variable "controller_ha" {
  description = "If true a HA controller cluster is deployed and configured"
  type        = bool
  default     = "false"
}
variable "register_controller" {
  description = "If enabled is set to true the controller will be registered and licensed with Avi Cloud Services. The Long Organization ID (organization_id) can be found from https://console.cloud.vmware.com/csp/gateway/portal/#/organization/info. The jwt_token can be retrieved at https://portal.avipulse.vmware.com/portal/controller/auth/cspctrllogin"
  sensitive   = false
  type        = object({ enabled = bool, jwt_token = string, email = string, organization_id = string })
  default     = { enabled = "false", jwt_token = "", email = "", organization_id = "" }
}
variable "create_networking" {
  description = "This variable controls the VPC and subnet creation for the Avi Controller. When set to false the custom_vpc_name and custom_subnetwork_name must be set."
  type        = bool
  default     = "true"
}
variable "create_firewall_rules" {
  description = "This variable controls the VPC firewall rule creation for the Avi deployment. When set to false the necessary firewall rules must be in place before the deployment"
  type        = bool
  default     = "true"
}
variable "controller_public_address" {
  description = "This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller."
  type        = bool
  default     = "false"
}
variable "create_cloud_router" {
  description = "This variable is used to create a GCP Cloud Router when both the create_networking variable = true and the vip_allocation_strategy = ILB"
  type        = bool
  default     = "false"
}
variable "avi_subnet" {
  description = "The CIDR that will be used for creating a subnet in the Avi VPC"
  type        = string
  default     = "10.255.1.0/24"
}
variable "custom_vpc_name" {
  description = "This field can be used to specify an existing VPC for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "custom_subnetwork_name" {
  description = "This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create_networking variable must also be set to false for this network to be used."
  type        = string
  default     = null
}
variable "create_iam" {
  description = "Create IAM Roles and Role Bindings necessary for the Avi GCP Full Access Cloud. If not set the Roles and permissions in this document must be associated with the controller service account - https://Avinetworks.com/docs/latest/gcp-full-access-roles-and-permissions/"
  type        = bool
  default     = "false"
}
variable "controller_default_password" {
  description = "This is the default password for the Avi controller image and can be found in the image download page."
  type        = string
  sensitive   = false
}
variable "controller_password" {
  description = "The password that will be used authenticating with the Avi Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters"
  type        = string
  sensitive   = false
  validation {
    condition     = length(var.controller_password) > 7
    error_message = "The controller_password value must be more than 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters."
  }
}
variable "service_account_email" {
  description = "This is the service account that will be leveraged by the Avi Controller. If the create-iam variable is true then this module will create the necessary custom roles and bindings for the SA"
  type        = string
}
variable "se_service_account" {
  description = "This is the service account that will be leveraged by the Avi Service Engines. This is optional and only needed if using service accounts are used for GCP firewall rules in 20.1.7 - https://avinetworks.com/docs/20.1/gcp-firewall-rules/#firewall-rule-filtering-with-service-accounts"
  type        = string
  default     = null
}
variable "controller_image_gs_path" {
  description = "The Google Storage path to the GCP Avi Controller tar.gz image file using the bucket/filename syntax"
  type        = string
}
variable "custom_machine_type" {
  description = "This value overides the machine type used for the Avi Controller"
  type        = string
  default     = ""
}
variable "boot_disk_size" {
  description = "The boot disk size for the Avi controller"
  type        = number
  default     = 128
  validation {
    condition     = var.boot_disk_size >= 128
    error_message = "The Controller boot disk size should be greater than or equal to 128 GB."
  }
}
variable "se_size" {
  description = "The CPU, Memory, Disk Size of the Service Engines. The default is 2 vCPU, 2 GB RAM, and a 15 GB Disk per Service Engine. Syntax [\"cpu_cores\", \"memory_in_GB\", \"disk_size_in_GB\"]"
  type        = list(string)
  default     = ["2", "2", "15"]
}
variable "se_ha_mode" {
  description = "The HA mode of the Service Engine Group. Possible values active/active, n+m, or active/standby"
  type        = string
  default     = "active/active"
  validation {
    condition     = contains(["active/active", "n+m", "active/standby"], var.se_ha_mode)
    error_message = "Acceptable values are active/active, n+m, or active/standby."
  }
}
variable "vip_allocation_strategy" {
  description = "The VIP allocation strategy for the GCP Cloud - ROUTES or ILB"
  type        = string
  default     = "ROUTES"

  validation {
    condition     = var.vip_allocation_strategy == "ROUTES" || var.vip_allocation_strategy == "ILB"
    error_message = "The vip_allocation_strategy value must be either ROUTES or ILB."
  }
}
variable "network_project" {
  description = "The GCP Network project that the Controller and SEs will use. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "service_engine_project" {
  description = "The project used for Avi Service Engines. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "storage_project" {
  description = "The storage project used for the Avi Controller and SE Image. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "server_project" {
  description = "The backend server GCP Project. If not set the project variable will be used"
  type        = string
  default     = ""
}
variable "configure_firewall_se_data" {
  description = "Configure Firewall rules for SE dataplane traffic. If set the firewall_se_data_rules and firewall_se_data_source_range must be set"
  type        = bool
  default     = "false"
}
variable "firewall_se_data_rules" {
  description = "The ports allowed for Virtual Services hosted on Services Engines. The configure_firewall_se_data variable must be set to true for this rule to be created"
  type        = list(object({ protocol = string, port = list(string) }))
  default     = [{ protocol = "tcp", port = ["443", "53"] }, { protocol = "udp", port = ["53"] }]
}
variable "firewall_se_data_source_range" {
  description = "The IP range allowed to access Virtual Services hosted on Service Engines. The configure_firewall_se_data and firewall_se_data_rules variables must also be set"
  type        = string
  default     = "0.0.0.0/0"
}
variable "firewall_controller_allow_source_range" {
  description = "The IP range allowed to connect to the Avi Controller. Access from all IP ranges will be allowed by default"
  type        = string
  default     = "0.0.0.0/0"
}
variable "dns_servers" {
  description = "The optional DNS servers that will be used for local DNS resolution by the controller. Example [\"8.8.4.4\", \"8.8.8.8\"]"
  type        = list(string)
  default     = null
}
variable "dns_search_domain" {
  description = "The optional DNS search domain that will be used by the controller"
  type        = string
  default     = ""
}
variable "ntp_servers" {
  description = "The NTP Servers that the Avi Controllers will use. The server should be a valid IP address (v4 or v6) or a DNS name. Valid options for type are V4, DNS, or V6"
  type        = list(object({ addr = string, type = string }))
  default     = [{ addr = "0.us.pool.ntp.org", type = "DNS" }, { addr = "1.us.pool.ntp.org", type = "DNS" }, { addr = "2.us.pool.ntp.org", type = "DNS" }, { addr = "3.us.pool.ntp.org", type = "DNS" }]
}
variable "email_config" {
  description = "The Email settings that will be used for sending password reset information or for trigged alerts. The default setting will send emails directly from the Avi Controller"
  sensitive   = false
  type        = object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })
  default     = { smtp_type = "SMTP_LOCAL_HOST", from_email = "admin@avicontroller.net", mail_server_name = "localhost", mail_server_port = "25", auth_username = "", auth_password = "" }
}