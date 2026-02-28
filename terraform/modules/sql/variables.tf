variable "sql_server_name" {}
variable "rg_name" {}
variable "location" {}
variable "sql_admin_username" {}
variable "sql_admin_password" {}
variable "db_name" {}
variable "allow_azure_services" {
  type    = bool
  default = true
}
variable "local_ip" {
    type = string
}