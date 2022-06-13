output "controllers" {
  description = "The AVI Controller(s) Information"
  value = ([for s in google_compute_instance.avi_controller : merge(
    { "name" = s.name },
    { "private_ip_address" = s.network_interface[0].network_ip },
    var.controller_public_address ? { "public_ip_address" = s.network_interface[0].access_config[0].nat_ip } : {}
    )
    ]
  )
}