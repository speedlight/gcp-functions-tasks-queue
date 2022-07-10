variable "project_id" {
  type = string
  default = "ringed-enigma-334420"
}

variable "region" {
  type = string
  default = "northamerica-northeast1"
}

variable "bucket_name" {
  type = string
  default = "task-queue"
}

variable "functions_runtime" {
  type = string
  default = "nodejs16"
}

variable "queue_name" {
  type = string
  default = "enqueuer-logger"
}

variable "left_function_name" {
  type = string
  default = "enqueuer"
}

variable "right_function_name" {
  type = string
  default = "enqueuer"
}
