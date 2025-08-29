resource "google_logging_project_bucket_config" "log_analytics_bucket" {
  depends_on       = [google_project_service.api_services]
  description      = "Bucket for storing logs and analytics data"
  project          = var.project_id
  bucket_id        = "_Default"
  location         = "global"
  enable_analytics = true
  retention_days   = 1

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_logging_project_sink" "route_to_log_analytics" {
  depends_on = [
    google_project_service.api_services,
    google_logging_project_bucket_config.log_analytics_bucket
  ]
  description            = "Route logs to the analytics bucket"
  name                   = "vpc-logs-to-analytics"
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/_Default"
  filter                 = ""
  unique_writer_identity = true
}