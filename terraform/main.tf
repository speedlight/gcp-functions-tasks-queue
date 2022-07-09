terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  =  var.region
}

resource "google_storage_bucket" "bucket" {
  name = var.bucket_name
  project = var.project_id
  location  =  var.region
}

data "archive_file" "enqueuer" {
  type        = "zip"
  output_path = "${path.module}/files/enqueuer.zip"
  source {
    content  = "${file("../enqueuer.js")}"
    filename = "index.js"
  }
  source {
    content  = "${file("../package.json")}"
    filename = "package.json"
  }
}

data "archive_file" "logger" {
  type        = "zip"
  output_path = "${path.module}/files/logger.zip"
  source {
    content  = "${file("../logger.js")}"
    filename = "index.js"
  }
  source {
    content  = "${file("../package.json")}"
    filename = "package.json"
  }
}

resource "google_storage_bucket_object" "enqueuer" {
  name   = "enqueuer.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.module}/files/enqueuer.zip"
  depends_on = [data.archive_file.enqueuer]
}

resource "google_storage_bucket_object" "logger" {
  name   = "logger.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.module}/files/logger.zip"
  depends_on = [data.archive_file.logger]
}

resource "google_cloudfunctions_function" "enqueuer" {
  name        = "enqueuer"
  description = "Enqueuer"
  runtime     = var.functions_runtime
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.enqueuer.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "mainFunction"
}

resource "google_cloudfunctions_function" "logger" {
  name        = "logger"
  description = "Logger"
  runtime     = var.functions_runtime
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.logger.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "mainFunction"
}

resource "google_cloudfunctions_function_iam_member" "enqueuer-invoker" {
  project        = google_cloudfunctions_function.enqueuer.project
  region         = google_cloudfunctions_function.enqueuer.region
  cloud_function = google_cloudfunctions_function.enqueuer.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "logger-invoker" {
  project        = google_cloudfunctions_function.logger.project
  region         = google_cloudfunctions_function.logger.region
  cloud_function = google_cloudfunctions_function.logger.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

/*
resource "google_cloud_tasks_queue" "enqueuer-logger" {
  name     = "enqueuer-logger"
  location = var.region
  rate_limits {
    max_concurrent_dispatches = 100
  }
  retry_config {
    max_attempts = 3
    min_backoff  = "5s"
  }
}
*/
