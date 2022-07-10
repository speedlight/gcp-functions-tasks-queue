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

data "archive_file" "left_function_zip" {
  type        = "zip"
  output_path = "${path.module}/files/left_function.zip"
  source {
    content  = "${file("../enqueuer.js")}"
    filename = "index.js"
  }
  source {
    content  = "${file("../package.json")}"
    filename = "package.json"
  }
}

data "archive_file" "right_function_zip" {
  type        = "zip"
  output_path = "${path.module}/files/right_function.zip"
  source {
    content  = "${file("../logger.js")}"
    filename = "index.js"
  }
  source {
    content  = "${file("../package.json")}"
    filename = "package.json"
  }
}

resource "google_storage_bucket_object" "left_function_object" {
  name   = "enqueuer.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.module}/files/enqueuer.zip"
  depends_on = [data.archive_file.left_function_zip]
}

resource "google_storage_bucket_object" "right_function_object" {
  name   = "logger.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.module}/files/logger.zip"
  depends_on = [data.archive_file.right_function_zip]
}

resource "google_cloudfunctions_function" "left_function" {
  name        = var.left_function_name
  description = "Enqueuer"
  runtime     = var.functions_runtime
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.left_function_object.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "mainFunction"
}

resource "google_cloudfunctions_function" "right_function" {
  name        = var.right_function_name
  description = "Logger"
  runtime     = var.functions_runtime
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.right_function_object.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "mainFunction"
}

resource "google_cloudfunctions_function_iam_member" "left-function-invoker" {
  project        = google_cloudfunctions_function.left_function.project
  region         = google_cloudfunctions_function.left_function.region
  cloud_function = google_cloudfunctions_function.left_function.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "right-function-invoker" {
  project        = google_cloudfunctions_function.right_function.project
  region         = google_cloudfunctions_function.right_function.region
  cloud_function = google_cloudfunctions_function.right_function.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

/*
resource "google_cloud_tasks_queue" "functions_queue" {
  name     = var.queue_name
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
