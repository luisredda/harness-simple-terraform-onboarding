variable "api_key" {
  description = "API key for the Harness account"
}

variable "account_id" {
  description = "ID of the Harness account"
}

variable "project_identifier" {
  description = "Identifier for the Harness project"
}

variable "project_name" {
  description = "Name for the Harness project"
}

variable "org_id" {
  description = "ID of the Harness organization"
}

variable "project_color" {
  description = "Color for the Harness project"
}

variable "service_identifier" {
  description = "Identifier for the Harness service"
}

variable "service_name" {
  description = "Name for the Harness service"
}

variable "service_description" {
  description = "Description for the Harness service"
}

variable "environment_id" {
  description = "ID for the Harness Environment"
}

variable "environment_name" {
  description = "Name for the Harness Environment"
}

variable "infra_id" {
  description = "ID for the Harness Infrastructure Definition"
}

variable "infra_name" {
  description = "Name for the Harness Infrastructure"
}

variable "tf_backend" {
  description = "Terraform Backend File"
  default = "terraform.tfstate"
}
