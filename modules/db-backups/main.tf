resource "google_storage_bucket" "db-backups" {
  project       = var.project_id
  name          = "db-backups-${var.project_id}"
  location      = "EU"
  storage_class = "MULTI_REGIONAL"
}

data "archive_file" "backupZipFile" {
  type        = "zip"
  output_path = "${path.module}/backupCloudFunction/backup.zip"
source {
    content  = "${file("${path.module}/backupCloudFunction/index.js")}"
    filename = "index.js"
  }
source {
    content  = "${file("${path.module}/backupCloudFunction/package.json")}"
    filename = "package.json"
  }
}

resource "google_storage_bucket_object" "archive" {
  name   = "cloudFunctions/backup-${lower(replace(base64encode(data.archive_file.backupZipFile.output_md5), "=", ""))}.zip"
  bucket = google_storage_bucket.db-backups.name
  # Source path is relative to where the module is used : to improve
  source     = data.archive_file.backupZipFile.output_path
  depends_on = [data.archive_file.backupZipFile]
}

resource "google_storage_bucket_iam_member" "editor" {
  bucket = google_storage_bucket.db-backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_cloudfunctions_function" "backupFunction" {
  name        = "backup"
  description = "Performs a backup of the specified database in the db-backups bucket"
  runtime     = "nodejs10"
  project     = var.project_id
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.db-backups.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = "backup"
  region                = "europe-west2"
environment_variables = {
    PROJECT_ID        = var.project_id,
    DB_INSTANCE_NAME  = var.db_instance_name,
    BUCKET_NAME       = google_storage_bucket.db-backups.name
    DB_NAME_TO_EXPORT = var.db_name_to_export
  }
}

resource "google_cloud_scheduler_job" "backupJob" {
  project     = var.project_id
  region      = var.scheduler_region
  name        = "backup-job"
  description = "Create a backup of the database"
  schedule    = "0 4 * * *"
  time_zone   = "Europe/Paris"
http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.backupFunction.https_trigger_url
  }
}