resource "google_compute_firewall" "avi_controller_mgmt" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.name_prefix}-avi-controller-mgmt"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "5054"]
  }

  source_ranges = [var.firewall_controller_allow_source_range]
  target_tags   = ["avi-controller"]
  depends_on    = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "avi_controller_to_controller" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.name_prefix}-avi-controller-to-controller"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "8443"]
  }

  source_tags = ["avi-controller"]
  target_tags = ["avi-controller"]
  depends_on  = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "avi_se_to_se" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.name_prefix}-avi-se-to-se"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name

  allow {
    protocol = 75
  }

  allow {
    protocol = 97
  }

  allow {
    protocol = "udp"
    ports    = ["1550"]
  }

  source_tags = ["avi-se"]
  target_tags = ["avi-se"]
  depends_on  = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "avi_se_mgmt" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.name_prefix}-avi-se-mgmt"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name

  allow {
    protocol = "udp"
    ports    = ["123"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "8443"]
  }

  source_tags = ["avi-se"]
  target_tags = ["avi-controller"]
  depends_on  = [google_compute_network.vpc_network]
}
resource "google_compute_firewall" "avi_se_data" {
  count   = var.create_firewall_rules ? var.configure_firewall_se_data ? 1 : 0 : 0
  name    = "${var.name_prefix}-avi-se-data"
  project = var.network_project != "" ? var.network_project : var.project
  network = var.create_networking ? google_compute_network.vpc_network[0].name : var.custom_vpc_name

  dynamic "allow" {
    for_each = var.firewall_se_data_rules
    content {
      protocol = allow.value["protocol"]
      ports    = allow.value["port"]
    }
  }
  source_ranges = [var.firewall_se_data_source_range]
  target_tags   = ["avi-se"]
  depends_on    = [google_compute_network.vpc_network]
}