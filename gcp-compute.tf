locals {
  # Controller Settings used as Ansible Variables
  cloud_settings = {
    se_vpc_network_name             = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name
    se_mgmt_subnet_name             = var.create_networking ? google_compute_subnetwork.avi[0].name : var.custom_subnetwork_name
    controller_public_address       = var.controller_public_address
    vpc_project_id                  = var.network_project != "" ? var.network_project : var.project
    avi_version                     = var.avi_version
    dns_servers                     = var.dns_servers
    dns_search_domain               = var.dns_search_domain
    ntp_servers                     = var.ntp_servers
    email_config                    = var.email_config
    region                          = var.region
    se_project_id                   = var.service_engine_project != "" ? var.service_engine_project : var.project
    gcs_project_id                  = var.storage_project != "" ? var.storage_project : var.project
    name_prefix                     = var.name_prefix
    se_size                         = var.se_size
    gslb_se_size                    = var.gslb_se_size
    vip_allocation_strategy         = var.vip_allocation_strategy
    zones                           = data.google_compute_zones.available.names
    controller_ha                   = var.controller_ha
    register_controller             = var.register_controller
    controller_ip                   = local.controller_ip
    controller_names                = local.controller_names
    cloud_router                    = var.create_networking ? var.vip_allocation_strategy == "ILB" ? google_compute_router.avi[0].name : null : null
    configure_ipam_profile          = var.configure_ipam_profile
    ipam_networks                   = var.ipam_networks
    configure_dns_profile           = var.configure_dns_profile
    dns_service_domain              = var.dns_service_domain
    configure_dns_vs                = var.configure_dns_vs
    dns_vs_settings                 = var.dns_vs_settings
    configure_gslb                  = var.configure_gslb
    configure_gslb_additional_sites = var.configure_gslb_additional_sites
    gslb_site_name                  = var.gslb_site_name
    gslb_domains                    = var.gslb_domains
    additional_gslb_sites           = var.additional_gslb_sites
    create_gslb_se_group            = var.create_gslb_se_group
    se_ha_mode                      = var.se_ha_mode
    se_service_account              = var.se_service_account
    avi_upgrade                     = var.avi_upgrade
  }
  controller_sizes = {
    small  = "custom-8-24576"
    medium = "custom-16-32768"
    large  = "custom-24-49152"
  }

  controller_names = google_compute_instance.avi_controller[*].name
  controller_ip    = google_compute_instance.avi_controller[*].network_interface[0].network_ip
}
resource "google_compute_instance" "avi_controller" {
  count                     = var.controller_ha ? 3 : 1
  name                      = "${var.name_prefix}-avi-controller-${count.index + 1}"
  machine_type              = var.custom_machine_type == "" ? local.controller_sizes[var.controller_size] : var.custom_machine_type
  zone                      = data.google_compute_zones.available.names[count.index]
  allow_stopping_for_update = "true"
  tags                      = ["avi-controller"]
  boot_disk {
    initialize_params {
      image = google_compute_image.controller.name
      size  = var.boot_disk_size
      type  = "pd-ssd"
    }
  }
  network_interface {
    subnetwork         = var.create_networking ? google_compute_subnetwork.avi[0].name : var.custom_subnetwork_name
    subnetwork_project = var.network_project == "" ? null : var.network_project
    dynamic "access_config" {
      for_each = var.controller_public_address ? [""] : []
      content {}
    }
  }
  timeouts {
    create = "30m"
    delete = "30m"
  }
  service_account {
    email  = data.google_service_account.avi.email
    scopes = ["cloud-platform"]
  }
  provisioner "local-exec" {
    command = var.controller_public_address ? "bash ${path.module}/files/change-controller-password.sh --controller-address '${self.network_interface[0].access_config[0].nat_ip}' --current-password '${var.controller_default_password}' --new-password '${var.controller_password}'" : "bash ${path.module}/files/change-controller-password.sh --controller-address '${self.network_interface[0].network_ip}' --current-password '${var.controller_default_password}' --new-password '${var.controller_password}'"
  }
  depends_on = [google_compute_image.controller]
}
resource "null_resource" "ansible_provisioner" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    controller_instance_ids = join(",", google_compute_instance.avi_controller.*.name)
  }
  connection {
    type     = "ssh"
    host     = var.controller_public_address ? google_compute_instance.avi_controller[0].network_interface[0].access_config[0].nat_ip : google_compute_instance.avi_controller[0].network_interface[0].network_ip
    user     = "admin"
    timeout  = "600s"
    password = var.controller_password
  }
  provisioner "file" {
    source      = "${path.module}/files/avi_pulse_registration.py"
    destination = "/home/admin/avi_pulse_registration.py"
  }
  provisioner "file" {
    source      = "${path.module}/files/views_albservices.patch"
    destination = "/home/admin/views_albservices.patch"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-controller-gcp-all-in-one-play.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/avi-controller-gcp-all-in-one-play.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-cloud-services-registration.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/avi-cloud-services-registration.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-upgrade.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/avi-upgrade.yml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/files/avi-cleanup.yml.tpl",
    local.cloud_settings)
    destination = "/home/admin/avi-cleanup.yml"
  }
  provisioner "remote-exec" {
    inline = var.configure_controller ? [
      "ansible-playbook avi-controller-gcp-all-in-one-play.yml -e password='${var.controller_password}' 2> ansible-error.log | tee ansible-playbook.log",
      "echo Controller Configuration Completed"
    ] : ["ansible-playbook avi-controller-gcp-all-in-one-play.yml --tags register_controller -e password='${var.controller_password}' 2> ansible-error.log | tee ansible-playbook.log"]
  }
  provisioner "remote-exec" {
    inline = var.register_controller["enabled"] ? [
      "ansible-playbook avi-cloud-services-registration.yml -e password=${var.controller_password} 2>> ansible-error.log | tee -a ansible-playbook.log",
      "echo Controller Registration Completed"
    ] : ["echo Controller Registration Skipped"]
  }
  provisioner "remote-exec" {
    inline = var.avi_upgrade["enabled"] ? [
      "ansible-playbook avi-upgrade.yml -e password=${var.controller_password} -e upgrade_type=${var.avi_upgrade["upgrade_type"]} 2>> ansible-error.log | tee -a ansible-playbook.log",
      "echo Avi upgrade completed"
    ] : ["echo Avi upgrade skipped"]
  }
}