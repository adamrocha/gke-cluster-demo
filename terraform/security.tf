# Cloud Armor security policy for production workloads
resource "google_compute_security_policy" "cloud_armor_policy" {
  name        = "cloud-armor-policy"
  description = "Cloud Armor security policy for GKE workloads"

  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule - allow all traffic"
  }

  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = 2000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limiting - 100 requests per minute per IP (CVE: N/A)"
  }

  rule {
    action   = "deny(403)"
    priority = 3000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL injection protection (e.g., CVE-2023-34362)"
  }

  rule {
    action   = "deny(403)"
    priority = 4000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS protection (e.g., CVE-2020-11022, CVE-2020-11023)"
  }

  rule {
    action   = "deny(403)"
    priority = 5000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('lfi-stable')"
      }
    }
    description = "Local file inclusion protection (e.g., CVE-2021-41773)"
  }

  rule {
    action   = "deny(403)"
    priority = 6000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rce-stable')"
      }
    }
    description = "Remote code execution protection (e.g., CVE-2022-22965)"
  }

  rule {
    action   = "deny(403)"
    priority = 7000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('scannerdetection-stable')"
      }
    }
    description = "Scanner detection (CVE: N/A)"
  }

  rule {
    action   = "deny(403)"
    priority = 8000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('protocolattack-stable')"
      }
    }
    description = "Protocol attack protection (e.g., CVE-2023-25690)"
  }

  rule {
    action   = "deny(403)"
    priority = 9000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sessionfixation-stable')"
      }
    }
    description = "Session fixation protection (e.g., CVE-2021-32618)"
  }

  rule {
    action   = "deny(403)"
    priority = 1
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('cve-canary')"
      }
    }
    description = "CVE canary detection (CVE-2021-44228)"
  }


  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

# Backend security policy output for use with GKE Ingress
output "cloud_armor_policy_id" {
  value       = google_compute_security_policy.cloud_armor_policy.id
  description = "Cloud Armor security policy ID to attach to backend services"
}

output "cloud_armor_policy_self_link" {
  value       = google_compute_security_policy.cloud_armor_policy.self_link
  description = "Cloud Armor security policy self-link"
}
