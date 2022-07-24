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
variable "controller_size" {
  description = "This value determines the number of vCPUs and memory allocated for the Avi Controller. Possible values are small, medium, or large."
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.controller_size)
    error_message = "Acceptable values are small, medium, or large."
  }
}
variable "configure_ipam_profile" {
  description = "Configure Avi IPAM Profile for Virtual Service Address Allocation. If set to true the virtualservice_network variable must also be set"
  type        = bool
  default     = "false"
}
variable "ipam_networks" {
  description = "This variable configures the IPAM network(s). Example: [{ network = \"192.168.1.0/24\" , static_pool = [\"192.168.1.10\",\"192.168.1.30\"]}]"
  type        = list(object({ network = string, static_pool = list(string) }))
  default     = [{ network = "", static_pool = [""] }]
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
  description = "The DNS Virtual Service settings. With the auto_allocate_ip option is set to \"true\" the VS IP address will be allocated via an IPAM profile. Example:{ auto_allocate_ip = \"true\", auto_allocate_public_ip = \"true\", vs_ip = \"\", network = \"192.168.20.0/24\" }"
  type        = object({ auto_allocate_ip = bool, auto_allocate_public_ip = bool, vs_ip = string, network = string })
  default     = null
}
variable "configure_gslb" {
  description = "Configure GSLB. The gslb_site_name, gslb_domains, and configure_dns_vs variables must also be set. Optionally the additional_gslb_sites variable can be used to add active GSLB sites"
  type        = bool
  default     = "false"
}
variable "gslb_se_size" {
  description = "The CPU, Memory, Disk Size of the Service Engines. The default is 2 vCPU, 8 GB RAM, and a 30 GB Disk per Service Engine. Syntax [\"cpu_cores\", \"memory_in_GB\", \"disk_size_in_GB\"]"
  type        = list(string)
  default     = ["2", "8", "30"]
}
variable "gslb_site_name" {
  description = "The name of the GSLB site the deployed Controller(s) will be a member of."
  type        = string
  default     = ""
}
variable "gslb_domains" {
  description = "A list of GSLB domains that will be configured"
  type        = list(string)
  default     = [""]
}
variable "configure_gslb_additional_sites" {
  description = "Configure Additional GSLB Sites. The additional_gslb_sites, gslb_site_name, gslb_domains, and configure_dns_vs variables must also be set. Optionally the additional_gslb_sites variable can be used to add active GSLB sites"
  type        = bool
  default     = "false"
}
variable "additional_gslb_sites" {
  description = "The Names and IP addresses of the GSLB Sites that will be configured."
  type        = list(object({ name = string, ip_address_list = list(string), dns_vs_name = string }))
  default     = [{ name = "", ip_address_list = [""], dns_vs_name = "" }]
}
variable "create_gslb_se_group" {
  description = "Create a SE group for GSLB. This option only applies when configure_gslb is set to true"
  type        = bool
  default     = "true"
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
  description = "If true the controller will be register and licensed with Avi Cloud Services. Variables with registration_ are required for registration to be successful"
  type        = bool
  default     = "false"
}
variable "registration_jwt" {
  description = "Registration JWT Token for Avi Cloud Services. This token can be retrieved at https://portal.avipulse.vmware.com/portal/controller/auth/cspctrllogin"
  type        = string
  default     = ""
}
variable "registration_email" {
  description = "Registration email address for Avi Cloud Services"
  type        = string
  default     = ""
}
variable "registration_account_id" {
  description = "Registration account ID for Avi Cloud Services"
  type        = string
  default     = ""
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
  sensitive   = true
  type        = object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })
  default     = { smtp_type = "SMTP_LOCAL_HOST", from_email = "admin@avicontroller.net", mail_server_name = "localhost", mail_server_port = "25", auth_username = "", auth_password = "" }
}