resource "google_compute_network" "vpc_network" {
  count                   = var.create_networking ? 1 : 0
  name                    = "${var.name_prefix}-avi-vpc"
  project                 = var.network_project != "" ? var.network_project : var.project
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "avi" {
  count         = var.create_networking ? 1 : 0
  name          = "${var.name_prefix}-avi-subnet-${var.region}"
  project       = var.network_project != "" ? var.network_project : var.project
  ip_cidr_range = var.avi_subnet
  network       = google_compute_network.vpc_network[0].name
  region        = var.region
  depends_on    = [google_compute_network.vpc_network]
}
resource "google_compute_router" "avi" {
  count   = var.create_networking ? var.vip_allocation_strategy == "ILB" ? var.create_cloud_router ? 1 : 0 : 0 : 0
  name    = "${var.name_prefix}-avi-router"
  network = google_compute_network.vpc_network[0].name
}