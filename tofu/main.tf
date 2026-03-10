provider "docker" {}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "terraform_data" "k3d_cluster" {
  input = {
    name  = var.k3d_cluster_name
    image = "rancher/k3s:${var.k3s_version}"
  }

  provisioner "local-exec" {
    command = "k3d cluster create ${self.input.name} --image ${self.input.image} --servers 1 --agents 0 -p '8080:80@loadbalancer'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.input.name}"
  }
}

resource "postgresql_role" "postgrest_user" {
  name      = var.postgrest_user
  login     = true
  password  = var.postgrest_password
  superuser = true

  depends_on = [docker_container.postgres]
}

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_container" "postgres" {
  name  = "postgres-infra-takehome"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=app"
  ]

  ports {
    internal = 5432
    external = var.postgres_port
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  restart = "unless-stopped"
}

resource "docker_volume" "postgres_data" {
  name = "postgres-infra-takehome-data"
}

provider "postgresql" {
  host     = "localhost"
  port     = var.postgres_port
  username = "postgres"
  password = var.postgres_password
  sslmode  = "disable"
}

resource "postgresql_database" "postgrest" {
  name       = "postgrest"
  depends_on = [docker_container.postgres]
}

# ---------------------------------
# Grant usage on public schema
# ---------------------------------
resource "postgresql_grant" "postgrest_schema_usage" {
  database    = postgresql_database.postgrest.name
  role        = postgresql_role.postgrest_user.name
  schema      = "public"
  object_type = "schema"

  privileges = ["USAGE"]

  depends_on = [
    postgresql_database.postgrest,
    postgresql_role.postgrest_user
  ]
}

# ---------------------------------
# Grant SELECT on all tables
# ---------------------------------
resource "postgresql_grant" "postgrest_table_select" {
  database    = postgresql_database.postgrest.name
  role        = postgresql_role.postgrest_user.name
  schema      = "public"
  object_type = "table"

  privileges = ["SELECT"]

  depends_on = [
    postgresql_database.postgrest,
    postgresql_role.postgrest_user
  ]
}

# -----------------------------
# Kubernetes Namespace
# -----------------------------
resource "kubernetes_namespace_v1" "postgrest" {
  metadata {
    name = "postgrest"
  }

  depends_on = [terraform_data.k3d_cluster]
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
    postgresql_role.postgrest_user
  ]
}
