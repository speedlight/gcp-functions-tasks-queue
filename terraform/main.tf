terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  project = "ringed-enigma-334420"
  region  = "northamerica-northeast1"
}

resource "google_storage_bucket" "bucket" {
  name = "enqueuer-and-view-child"
  location = "northamerica-northeast1"
  project = "ringed-enigma-334420"
}

data "archive_file" "enqueueChild" {
  type        = "zip"
  output_path = "${path.module}/files/enqueueChild.zip"
  source {
    content  = "${file("../enqueueChild.js")}"
    filename = "index.js"
  }
  source {
    content  = "${file("../package.json")}"
    filename = "package.json"
  }
}

data "archive_file" "viewChild" {
  type        = "zip"
  output_path = "${path.module}/files/viewChild.zip"
  source {
    content  = "${file("../viewChildAge.js")}"
    filename = "index.js"
  }
  source {
    content  = "${file("../package.json")}"
    filename = "package.json"
  }
}

resource "google_storage_bucket_object" "enqueue-archive" {
  name   = "enqueueChild.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.module}/files/enqueueChild.zip"
  depends_on = [data.archive_file.enqueueChild]
}

resource "google_storage_bucket_object" "view-archive" {
  name   = "viewChild.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.module}/files/viewChild.zip"
  depends_on = [data.archive_file.viewChild]
}

resource "google_cloudfunctions_function" "enqueue-function" {
  name        = "enqueueChild"
  description = "Enqueue Child"
  runtime     = "nodejs16"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.enqueue-archive.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "mainFunction"
}

resource "google_cloudfunctions_function" "view-function" {
  name        = "viewChild"
  description = "View Child"
  runtime     = "nodejs16"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.view-archive.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "mainFunction"
}

resource "google_cloudfunctions_function_iam_member" "enqueue-invoker" {
  project        = google_cloudfunctions_function.enqueue-function.project
  region         = google_cloudfunctions_function.enqueue-function.region
  cloud_function = google_cloudfunctions_function.enqueue-function.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "view-invoker" {
  project        = google_cloudfunctions_function.view-function.project
  region         = google_cloudfunctions_function.view-function.region
  cloud_function = google_cloudfunctions_function.view-function.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

/*
resource "google_cloud_tasks_queue" "childAge-03" {
  name     = "childAge-03"
  location = "northamerica-northeast1"
  rate_limits {
    max_concurrent_dispatches = 100
  }
  retry_config {
    max_attempts = 3
    min_backoff  = "5s"
  }
}
*/
