resource "null_resource" "configure_kubectl" {
  depends_on = [google_container_cluster.gke_cluster]

  triggers = {
    cluster_name = google_container_cluster.gke_cluster.name
    endpoint     = google_container_cluster.gke_cluster.endpoint
    master_auth  = sha1(jsonencode(google_container_cluster.gke_cluster.master_auth))
  }

  provisioner "local-exec" {
    command     = <<EOF
    gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} \
    --region=${var.region} \
    --project=${var.project_id}
    EOF
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "image_build" {
  provisioner "local-exec" {
    command     = "../scripts/image.sh"
    interpreter = ["bash", "-c"]
  }
}

data "http" "my_ip" {
  url = "https://4.ident.me"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}



// This file contains local variables used in the Terraform configuration.
// These variables are used to simplify the configuration and avoid repetition.

// IAM roles for the service account
/*
locals {
  sa_roles = [
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.networkUser",
    "roles/editor"
  ]
}

locals {
  api_services = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
}
*/