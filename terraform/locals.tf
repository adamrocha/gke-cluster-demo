resource "terraform_data" "update_kubeconfig" {
  depends_on = [google_container_cluster.gke_cluster_demo]

  triggers_replace = {
    cluster_name = google_container_cluster.gke_cluster_demo.name
    endpoint     = google_container_cluster.gke_cluster_demo.endpoint
    master_auth  = sha1(jsonencode(google_container_cluster.gke_cluster_demo.master_auth))
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "🔑 Updating kubeconfig for cluster ${google_container_cluster.gke_cluster_demo.name}..."
      
      # Use gcloud to get credentials and update kubeconfig
      gcloud container clusters get-credentials ${google_container_cluster.gke_cluster_demo.name} \
        --region=${var.region} \
        --project=${var.project_id} \
    EOT
    interpreter = ["bash", "-c"]
  }
}