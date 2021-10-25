resource "google_sql_database_instance" "teste-tc-3268" {
  project          = var.project_id
  name             = "teste-tc-3268"
  database_version = "POSTGRES_9_6"
  region           = "europe-west1"
  settings {
    tier = "db-custom-16-106496"
  }
}

module "db_backups" {
  source                = "../modules/db-backups"
  project_id            = var.project_id
  service_account_email = google_sql_database_instance.teste-tc-3268.service_account_email_address
  app_db_instance_name  = google_sql_database_instance.teste-tc-3268.name
  db_name_to_export     = "name-of-the-database-to-export"
  scheduler_region      = "europe-west1"
  db_instance_name      = var.db_instance_name
}
