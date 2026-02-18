resource "tls_private_key" "ingress_ssl_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ingress_ssl_cert" {
  private_key_pem = tls_private_key.ingress_ssl_key.private_key_pem

  subject {
    common_name  = google_compute_global_address.gke_lb_ip.address
    organization = "gke-cluster-demo"
  }

  ip_addresses = [
    google_compute_global_address.gke_lb_ip.address,
    "127.0.0.1"
  ]

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]

  validity_period_hours = 8760
  is_ca_certificate     = false
}

resource "google_compute_ssl_certificate" "hello_world_ingress_cert" {
  name        = "hello-world-ingress-cert"
  private_key = tls_private_key.ingress_ssl_key.private_key_pem
  certificate = tls_self_signed_cert.ingress_ssl_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}
