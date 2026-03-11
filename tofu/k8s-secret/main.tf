provider "kubernetes" {
  config_path = "~/.kube/config"
}

# -----------------------------
# Kubernetes Namespace
# -----------------------------
resource "kubernetes_namespace_v1" "postgrest" {
  metadata {
    name = "postgrest"
  }

}

resource "kubernetes_secret_v1" "postgrest_db" {
  metadata {
    name      = "postgrest-db"
    namespace = kubernetes_namespace_v1.postgrest.metadata[0].name
  }

  data = {
    PGRST_DB_URI = "postgres://${var.postgrest_user}:${var.postgrest_password}@host.k3d.internal:${var.postgres_port}/postgrest"
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace_v1.postgrest,
  ]
}
