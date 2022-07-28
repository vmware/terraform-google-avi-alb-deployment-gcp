# Avi ALB Controller Deployment on GCP Terraform module
This Terraform module creates and configures an AVI (NSX ALB) Controller on GCP

## Module Functions
The module is meant to be modular and can create all or none of the prerequiste resources needed for the Avi GCP Deployment including:
* VPC and Subnet for the Controller (optional with create_networking variable)
* IAM Roles and Role Bindings for supplied Service Account (optional with create_iam variable)
* GCP Compute Image from the provided bucket controller file
* Firewall Rules for Avi Controller and SE communication
* GCP Compute Instance using the Controller Compute Image

During the creation of the Controller instance the following initialization steps are performed:
* Change default password to user specified password
* Copy Ansible playbook to controller using the assigned public IP
* Run Ansible playbook to configure initial settings and GCP Full Access Cloud 

Optionally the following Avi configurations can be created:
* Avi IPAM Profile (configure_ipam_profile variable)
* Avi DNS Profile (configure_dns_profile variable)
* DNS Virtual Service (configure_dns_vs variable)

# Environment Requirements

## Google Cloud Platform
The following are GCP prerequisites for running this module:
* Service Account created for the Avi Controller
* Projects identified for the Controller, Network, Service Engines, Storage, and Backend Servers. By default this be the a single project as set by the "project" variable. Optionally the "network_project", "service_engine_project", "storage_project", and "server_project" variables can be set to use a different project than the project the Controller will be deployed to. 
* If more than 1 project will be used "Disable Cross-Project Service Account Usage" organizational policy must be set to "Not enforced" and the the Service Account must be added to those additional projects. 

## Google Provider
For authenticating to GCP you must leverage either the "GOOGLE_APPLICATION_CREDENTIALS={{path_to_service_account_key}}" environment variable or use "gcloud auth application-default login"
## Controller Image
The AVI Controller image for GCP should be uploaded to a GCP Cloud Storage bucket before running this module with the path specified in the controller-image-gs-path variable. This can be done with the following gsutil commands:

```bash
gsutil mb <bucket>
gsutil -m cp ./gcp_controller-<avi-version>.tar.gz  gs://<bucket>/
```
## Host OS 
The following packages must be installed on the host operating system:
* curl 

# Usage
```hcl
terraform {
  backend "local" {
  }
}
module "avi_controller_gcp" {
  source  = "vmware/avi-alb-deployment-gcp/google"
  version = "1.0.x"

  region = "us-west1"
  create_networking = "true"
  create_iam = "false"
  controller_default_password = "Value Redacted and available within the VMware Customer Portal"
  avi_version = "21.1.1"
  service_account_email = "<sa-account>@<project>.iam.gserviceaccount.com"
  controller_image_gs_path = "<bucket>/gcp_controller-21.1.1.tar.gz"
  controller_password = "password"
  name_prefix = "avi"
  project = "gcp-project"
}
output "controller_address" { 
  value = module.avi_controller_gcp.controllers
} 
```
## GSLB Deployment Example
```hcl
terraform {
  backend "local" {
  }
}
module "avi_controller_east" {
  source  = "vmware/avi-alb-deployment-gcp/google"
  version = "1.0.x"

  region                      = "us-east1"
  create_networking           = "false"
  custom_vpc_name             = "vpc"
  custom_subnetwork_name      = "subnet-east-1"
  create_iam                  = "false"
  avi_version                 = "21.1.1"
  controller_public_address   = "true"
  service_account_email       = "<email>@<account>.iam.gserviceaccount.com"
  controller_ha               = "true"
  controller_default_password = "<default-password>"
  controller_image_gs_path    = "<bucket>/gcp_controller-21.1.1.tar.gz"
  controller_password         = "<new-password>"
  name_prefix                 = "east1"
  project                     = "<project>"
  configure_ipam_profile      = "true"
  ipam_networks               = [{ network = "192.168.252.0/24" , static_pool = ["192.168.252.1", "192.168.252.254"]}]
  configure_dns_profile       = "true"
  dns_service_domain          = "east.domain"
  configure_dns_vs            = "true"
  dns_vs_settings             = { auto_allocate_ip = "true", auto_allocate_public_ip = "true", vs_ip = "", network = "192.168.252.0/24" }
  create_gslb_se_group        = "true"
  gslb_site_name              = "East1"
}
module "avi_controller_west" {
  source  = "vmware/avi-alb-deployment-gcp/google"
  version = "1.0.x"

  region                          = "us-west1"
  create_networking               = "false"
  custom_vpc_name                 = "vpc"
  custom_subnetwork_name          = "subnet-west-1"
  create_iam                      = "false"
  avi_version                     = "21.1.1"
  controller_public_address       = "true"
  service_account_email           = "<email>@<project>.iam.gserviceaccount.com"
  controller_ha                   = "true"
  controller_default_password     = "<default-password>"
  controller_image_gs_path        = "<bucket>/gcp_controller-21.1.1.tar.gz"
  controller_password             = "<new-password>"
  name_prefix                     = "west1"
  project                         = "<project>"
  configure_ipam_profile          = "true"
  ipam_networks                   = [{ network = "192.168.251.0/24" , static_pool = ["192.168.251.1", "192.168.251.254"]}]
  configure_dns_profile           = "true"
  dns_service_domain              = "west.domain"
  configure_dns_vs                = "true"
  dns_vs_settings                 = { auto_allocate_ip = "true", auto_allocate_public_ip = "true", vs_ip = "", network = "192.168.251.0/24" }
  configure_gslb                  = "true"
  gslb_site_name                  = "West1"
  gslb_domains                    = ["gslb.domain"]
  configure_gslb_additional_sites = "true"
  additional_gslb_sites           = [{name = "East1", ip_address = module.avi_controller_east.controllers[*].private_ip_address , dns_vs_name = "DNS-VS"}]
}
output "west_controller_ip" { 
  value = module.avi_controller_west.controllers
}
output "east_controller_ip" { 
  value = module.avi_controller_east.controllers
}
```
## Controller Sizing
The controller_size variable can be used to determine the vCPU and Memory resources allocated to the Avi Controller. There are 3 available sizes for the Controller as documented below:

| Size | vCPU Cores | Memory (GB)|
|------|-----------|--------|
| small | 8 | 24 |
| medium | 16 | 32 |
| large | 24 | 48 |

Additional resources on sizing the Avi Controller:

https://avinetworks.com/docs/latest/avi-controller-sizing/
https://avinetworks.com/docs/latest/system-limits/

## Day 1 Ansible Configuration and Avi Resource Cleanup
The module copies and runs an Ansible play for configuring the initial day 1 Avi config. The plays listed below can be reviewed by connecting to the Avi Controller by SSH. In an HA setup the first controller will have these files. 

### avi-controller-gcp-all-in-one-play.yml
This play will configure the Avi Cloud, Network, IPAM/DNS profiles, DNS Virtual Service, GSLB depending on the variables used by the module. The initial run of this play will be output into the ansible-playbook.log file which can be reviewed to determine what tasks were ran. 

Example run (appropriate variables should be used):
```bash
~$ ansible-playbook avi-controller-gcp-all-in-one-play.yml -e password='${var.controller_password}' > ansible-playbook-run.log
```

### avi-cleanup.yml
This play will disable all Virtual Services and delete all existing Avi service engines. This playbook should be ran before deleting the controller with terraform destroy to clean up the resources created by the Avi Controller. 

Example run (appropriate variables should be used):
```bash
~$ ansible-playbook avi-cleanup.yml -e password='${var.controller_password}'
```
## Contributing

The terraform-google-avi-alb-deployment-gcp project team welcomes contributions from the community. Before you start working with this project please read and sign our Contributor License Agreement (https://cla.vmware.com/cla/1/preview). If you wish to contribute code and you have not signed our Contributor Licence Agreement (CLA), our bot will prompt you to do so when you open a Pull Request. For any questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq). For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.6 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.25.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.1.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.25.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.1.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.avi_controller_mgmt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.avi_controller_to_controller](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.avi_se_data](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.avi_se_mgmt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.avi_se_to_se](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_image.controller](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_image) | resource |
| [google_compute_instance.avi_controller](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.vpc_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.avi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_subnetwork.avi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_project_iam_custom_role.autoscaling_se](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.cluster_vip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.ilb_byoip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.server](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.serviceengine](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.storage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.avi_autoscaling_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_cluster_vip_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_ilb_byoip_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_network_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_se_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_se_service_account_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_server_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.avi_storage_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [null_resource.ansible_provisioner](https://registry.terraform.io/providers/hashicorp/null/3.1.1/docs/resources/resource) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_service_account.avi](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_gslb_sites"></a> [additional\_gslb\_sites](#input\_additional\_gslb\_sites) | The Names and IP addresses of the GSLB Sites that will be configured. | `list(object({ name = string, ip_address_list = list(string), dns_vs_name = string }))` | <pre>[<br>  {<br>    "dns_vs_name": "",<br>    "ip_address_list": [<br>      ""<br>    ],<br>    "name": ""<br>  }<br>]</pre> | no |
| <a name="input_avi_subnet"></a> [avi\_subnet](#input\_avi\_subnet) | The CIDR that will be used for creating a subnet in the Avi VPC | `string` | `"10.255.1.0/24"` | no |
| <a name="input_avi_upgrade"></a> [avi\_upgrade](#input\_avi\_upgrade) | This variable determines if a patch upgrade is performed after install. The enabled key should be set to true and the url from the Avi Cloud Services portal for the should be set for the upgrade\_file\_uri key. Valid upgrade\_type values are patch or system | `object({ enabled = bool, upgrade_type = string, upgrade_file_uri = string })` | <pre>{<br>  "enabled": "false",<br>  "upgrade_file_uri": "",<br>  "upgrade_type": "patch"<br>}</pre> | no |
| <a name="input_avi_version"></a> [avi\_version](#input\_avi\_version) | The version of Avi that will be deployed | `string` | n/a | yes |
| <a name="input_boot_disk_size"></a> [boot\_disk\_size](#input\_boot\_disk\_size) | The boot disk size for the Avi controller | `number` | `128` | no |
| <a name="input_configure_dns_profile"></a> [configure\_dns\_profile](#input\_configure\_dns\_profile) | Configure Avi DNS Profile for DNS Record Creation for Virtual Services. If set to true the dns\_service\_domain variable must also be set | `bool` | `"false"` | no |
| <a name="input_configure_dns_vs"></a> [configure\_dns\_vs](#input\_configure\_dns\_vs) | Create DNS Virtual Service. The configure\_dns\_profile and configure\_ipam\_profile variables must be set to true and their associated configuration variables must also be set | `bool` | `"false"` | no |
| <a name="input_configure_firewall_se_data"></a> [configure\_firewall\_se\_data](#input\_configure\_firewall\_se\_data) | Configure Firewall rules for SE dataplane traffic. If set the firewall\_se\_data\_rules and firewall\_se\_data\_source\_range must be set | `bool` | `"false"` | no |
| <a name="input_configure_gslb"></a> [configure\_gslb](#input\_configure\_gslb) | Configure GSLB. The gslb\_site\_name, gslb\_domains, and configure\_dns\_vs variables must also be set. Optionally the additional\_gslb\_sites variable can be used to add active GSLB sites | `bool` | `"false"` | no |
| <a name="input_configure_gslb_additional_sites"></a> [configure\_gslb\_additional\_sites](#input\_configure\_gslb\_additional\_sites) | Configure Additional GSLB Sites. The additional\_gslb\_sites, gslb\_site\_name, gslb\_domains, and configure\_dns\_vs variables must also be set. Optionally the additional\_gslb\_sites variable can be used to add active GSLB sites | `bool` | `"false"` | no |
| <a name="input_configure_ipam_profile"></a> [configure\_ipam\_profile](#input\_configure\_ipam\_profile) | Configure Avi IPAM Profile for Virtual Service Address Allocation. If set to true the virtualservice\_network variable must also be set | `bool` | `"false"` | no |
| <a name="input_controller_default_password"></a> [controller\_default\_password](#input\_controller\_default\_password) | This is the default password for the Avi controller image and can be found in the image download page. | `string` | n/a | yes |
| <a name="input_controller_ha"></a> [controller\_ha](#input\_controller\_ha) | If true a HA controller cluster is deployed and configured | `bool` | `"false"` | no |
| <a name="input_controller_image_gs_path"></a> [controller\_image\_gs\_path](#input\_controller\_image\_gs\_path) | The Google Storage path to the GCP Avi Controller tar.gz image file using the bucket/filename syntax | `string` | n/a | yes |
| <a name="input_controller_password"></a> [controller\_password](#input\_controller\_password) | The password that will be used authenticating with the Avi Controller. This password be a minimum of 8 characters and contain at least one each of uppercase, lowercase, numbers, and special characters | `string` | n/a | yes |
| <a name="input_controller_public_address"></a> [controller\_public\_address](#input\_controller\_public\_address) | This variable controls if the Controller has a Public IP Address. When set to false the Ansible provisioner will connect to the private IP of the Controller. | `bool` | `"false"` | no |
| <a name="input_controller_size"></a> [controller\_size](#input\_controller\_size) | This value determines the number of vCPUs and memory allocated for the Avi Controller. Possible values are small, medium, or large. | `string` | `"small"` | no |
| <a name="input_create_cloud_router"></a> [create\_cloud\_router](#input\_create\_cloud\_router) | This variable is used to create a GCP Cloud Router when both the create\_networking variable = true and the vip\_allocation\_strategy = ILB | `bool` | `"false"` | no |
| <a name="input_create_firewall_rules"></a> [create\_firewall\_rules](#input\_create\_firewall\_rules) | This variable controls the VPC firewall rule creation for the Avi deployment. When set to false the necessary firewall rules must be in place before the deployment | `bool` | `"true"` | no |
| <a name="input_create_gslb_se_group"></a> [create\_gslb\_se\_group](#input\_create\_gslb\_se\_group) | Create a SE group for GSLB. This option only applies when configure\_gslb is set to true | `bool` | `"true"` | no |
| <a name="input_create_iam"></a> [create\_iam](#input\_create\_iam) | Create IAM Roles and Role Bindings necessary for the Avi GCP Full Access Cloud. If not set the Roles and permissions in this document must be associated with the controller service account - https://Avinetworks.com/docs/latest/gcp-full-access-roles-and-permissions/ | `bool` | `"false"` | no |
| <a name="input_create_networking"></a> [create\_networking](#input\_create\_networking) | This variable controls the VPC and subnet creation for the Avi Controller. When set to false the custom\_vpc\_name and custom\_subnetwork\_name must be set. | `bool` | `"true"` | no |
| <a name="input_custom_machine_type"></a> [custom\_machine\_type](#input\_custom\_machine\_type) | This value overides the machine type used for the Avi Controller | `string` | `""` | no |
| <a name="input_custom_subnetwork_name"></a> [custom\_subnetwork\_name](#input\_custom\_subnetwork\_name) | This field can be used to specify an existing VPC subnetwork for the controller and SEs. The create\_networking variable must also be set to false for this network to be used. | `string` | `null` | no |
| <a name="input_custom_vpc_name"></a> [custom\_vpc\_name](#input\_custom\_vpc\_name) | This field can be used to specify an existing VPC for the controller and SEs. The create\_networking variable must also be set to false for this network to be used. | `string` | `null` | no |
| <a name="input_dns_search_domain"></a> [dns\_search\_domain](#input\_dns\_search\_domain) | The optional DNS search domain that will be used by the controller | `string` | `""` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | The optional DNS servers that will be used for local DNS resolution by the controller. Example ["8.8.4.4", "8.8.8.8"] | `list(string)` | `null` | no |
| <a name="input_dns_service_domain"></a> [dns\_service\_domain](#input\_dns\_service\_domain) | The DNS Domain that will be available for Virtual Services. Avi will be the Authorative Nameserver for this domain and NS records may need to be created pointing to the Avi Service Engine addresses. An example is demo.Avi.com | `string` | `""` | no |
| <a name="input_dns_vs_settings"></a> [dns\_vs\_settings](#input\_dns\_vs\_settings) | The DNS Virtual Service settings. With the auto\_allocate\_ip option is set to "true" the VS IP address will be allocated via an IPAM profile. Example:{ auto\_allocate\_ip = "true", auto\_allocate\_public\_ip = "true", vs\_ip = "", network = "192.168.20.0/24" } | `object({ auto_allocate_ip = bool, auto_allocate_public_ip = bool, vs_ip = string, network = string })` | `null` | no |
| <a name="input_email_config"></a> [email\_config](#input\_email\_config) | The Email settings that will be used for sending password reset information or for trigged alerts. The default setting will send emails directly from the Avi Controller | `object({ smtp_type = string, from_email = string, mail_server_name = string, mail_server_port = string, auth_username = string, auth_password = string })` | <pre>{<br>  "auth_password": "",<br>  "auth_username": "",<br>  "from_email": "admin@avicontroller.net",<br>  "mail_server_name": "localhost",<br>  "mail_server_port": "25",<br>  "smtp_type": "SMTP_LOCAL_HOST"<br>}</pre> | no |
| <a name="input_firewall_controller_allow_source_range"></a> [firewall\_controller\_allow\_source\_range](#input\_firewall\_controller\_allow\_source\_range) | The IP range allowed to connect to the Avi Controller. Access from all IP ranges will be allowed by default | `string` | `"0.0.0.0/0"` | no |
| <a name="input_firewall_se_data_rules"></a> [firewall\_se\_data\_rules](#input\_firewall\_se\_data\_rules) | The ports allowed for Virtual Services hosted on Services Engines. The configure\_firewall\_se\_data variable must be set to true for this rule to be created | `list(object({ protocol = string, port = list(string) }))` | <pre>[<br>  {<br>    "port": [<br>      "443",<br>      "53"<br>    ],<br>    "protocol": "tcp"<br>  },<br>  {<br>    "port": [<br>      "53"<br>    ],<br>    "protocol": "udp"<br>  }<br>]</pre> | no |
| <a name="input_firewall_se_data_source_range"></a> [firewall\_se\_data\_source\_range](#input\_firewall\_se\_data\_source\_range) | The IP range allowed to access Virtual Services hosted on Service Engines. The configure\_firewall\_se\_data and firewall\_se\_data\_rules variables must also be set | `string` | `"0.0.0.0/0"` | no |
| <a name="input_gslb_domains"></a> [gslb\_domains](#input\_gslb\_domains) | A list of GSLB domains that will be configured | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| <a name="input_gslb_se_size"></a> [gslb\_se\_size](#input\_gslb\_se\_size) | The CPU, Memory, Disk Size of the Service Engines. The default is 2 vCPU, 8 GB RAM, and a 30 GB Disk per Service Engine. Syntax ["cpu\_cores", "memory\_in\_GB", "disk\_size\_in\_GB"] | `list(string)` | <pre>[<br>  "2",<br>  "8",<br>  "30"<br>]</pre> | no |
| <a name="input_gslb_site_name"></a> [gslb\_site\_name](#input\_gslb\_site\_name) | The name of the GSLB site the deployed Controller(s) will be a member of. | `string` | `""` | no |
| <a name="input_ipam_networks"></a> [ipam\_networks](#input\_ipam\_networks) | This variable configures the IPAM network(s). Example: [{ network = "192.168.1.0/24" , static\_pool = ["192.168.1.10","192.168.1.30"]}] | `list(object({ network = string, static_pool = list(string) }))` | <pre>[<br>  {<br>    "network": "",<br>    "static_pool": [<br>      ""<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | This prefix is appended to the names of the Controller and SEs | `string` | n/a | yes |
| <a name="input_network_project"></a> [network\_project](#input\_network\_project) | The GCP Network project that the Controller and SEs will use. If not set the project variable will be used | `string` | `""` | no |
| <a name="input_ntp_servers"></a> [ntp\_servers](#input\_ntp\_servers) | The NTP Servers that the Avi Controllers will use. The server should be a valid IP address (v4 or v6) or a DNS name. Valid options for type are V4, DNS, or V6 | `list(object({ addr = string, type = string }))` | <pre>[<br>  {<br>    "addr": "0.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "1.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "2.us.pool.ntp.org",<br>    "type": "DNS"<br>  },<br>  {<br>    "addr": "3.us.pool.ntp.org",<br>    "type": "DNS"<br>  }<br>]</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | The project used for the Avi Controller | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The Region that the Avi controller and SEs will be deployed to | `string` | n/a | yes |
| <a name="input_register_controller"></a> [register\_controller](#input\_register\_controller) | If enabled is set to true the controller will be registered and licensed with Avi Cloud Services. The Long Organization ID (organization\_id) can be found from https://console.cloud.vmware.com/csp/gateway/portal/#/organization/info. The jwt\_token can be retrieved at https://portal.avipulse.vmware.com/portal/controller/auth/cspctrllogin | `object({ enabled = bool, jwt_token = string, email = string, organization_id = string })` | <pre>{<br>  "email": "",<br>  "enabled": "false",<br>  "jwt_token": "",<br>  "organization_id": ""<br>}</pre> | no |
| <a name="input_se_ha_mode"></a> [se\_ha\_mode](#input\_se\_ha\_mode) | The HA mode of the Service Engine Group. Possible values active/active, n+m, or active/standby | `string` | `"active/active"` | no |
| <a name="input_se_service_account"></a> [se\_service\_account](#input\_se\_service\_account) | This is the service account that will be leveraged by the Avi Service Engines. This is optional and only needed if using service accounts are used for GCP firewall rules in 20.1.7 - https://avinetworks.com/docs/20.1/gcp-firewall-rules/#firewall-rule-filtering-with-service-accounts | `string` | `null` | no |
| <a name="input_se_size"></a> [se\_size](#input\_se\_size) | The CPU, Memory, Disk Size of the Service Engines. The default is 2 vCPU, 2 GB RAM, and a 15 GB Disk per Service Engine. Syntax ["cpu\_cores", "memory\_in\_GB", "disk\_size\_in\_GB"] | `list(string)` | <pre>[<br>  "2",<br>  "2",<br>  "15"<br>]</pre> | no |
| <a name="input_server_project"></a> [server\_project](#input\_server\_project) | The backend server GCP Project. If not set the project variable will be used | `string` | `""` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | This is the service account that will be leveraged by the Avi Controller. If the create-iam variable is true then this module will create the necessary custom roles and bindings for the SA | `string` | n/a | yes |
| <a name="input_service_engine_project"></a> [service\_engine\_project](#input\_service\_engine\_project) | The project used for Avi Service Engines. If not set the project variable will be used | `string` | `""` | no |
| <a name="input_storage_project"></a> [storage\_project](#input\_storage\_project) | The storage project used for the Avi Controller and SE Image. If not set the project variable will be used | `string` | `""` | no |
| <a name="input_vip_allocation_strategy"></a> [vip\_allocation\_strategy](#input\_vip\_allocation\_strategy) | The VIP allocation strategy for the GCP Cloud - ROUTES or ILB | `string` | `"ROUTES"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_controllers"></a> [controllers](#output\_controllers) | The AVI Controller(s) Information |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->