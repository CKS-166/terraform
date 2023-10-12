variable "prefix" {
  default = "tf_env"
}

variable "env" {
  nullable = false
  type     = string
}

variable "region" {
  nullable = false
  type     = string
}
