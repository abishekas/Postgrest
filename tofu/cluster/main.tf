provider "docker" {}

provider "postgresql" {
  host     = "localhost"
  port     = var.postgres_port
  username = "postgres"
  password = var.postgres_password
  sslmode  = "disable"
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

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

resource "docker_volume" "postgres_data" {
  name = "postgres-infra-takehome-data"
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

  depends_on = [
    terraform_data.k3d_cluster
  ]
}

#########################################################
# WAIT UNTIL POSTGRESQL IS READY
#########################################################

resource "terraform_data" "wait_for_postgres" {

  depends_on = [
    docker_container.postgres
  ]

  provisioner "local-exec" {
    command = <<EOT
echo "Waiting for PostgreSQL to become ready..."

until docker exec postgres-infra-takehome pg_isready -U postgres >/dev/null 2>&1
do
  sleep 2
done

echo "PostgreSQL is ready."
EOT
  }
}

#########################################################
# DATABASE
#########################################################

resource "postgresql_database" "postgrest" {
  name = "postgrest"

  depends_on = [
    terraform_data.wait_for_postgres
  ]
}

#########################################################
# ROLE
#########################################################

resource "postgresql_role" "postgrest_user" {
  name      = var.postgrest_user
  login     = true
  password  = var.postgrest_password
  superuser = true

  depends_on = [
    terraform_data.wait_for_postgres
  ]
}

#########################################################
# GRANT USAGE ON SCHEMA
#########################################################

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

#########################################################
# GRANT SELECT ON TABLES
#########################################################

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
