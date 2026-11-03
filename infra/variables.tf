variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "image_tag" {
  default = "bootstrap"
}

variable "task_cpu" {
  default = 256
}

variable "task_memory" {
  default = 512
}

variable "desired_count" {
  default = 1
}
