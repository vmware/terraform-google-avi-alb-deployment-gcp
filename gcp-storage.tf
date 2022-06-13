resource "google_compute_image" "controller" {
  name = "${var.name_prefix}-avi-controller-${replace(var.avi_version, ".", "-")}"

  raw_disk {
    source = "https://storage.googleapis.com/${var.controller_image_gs_path}"
  }
}