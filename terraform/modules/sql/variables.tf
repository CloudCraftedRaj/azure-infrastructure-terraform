variable "sql_server_name" {}
variable "rg_name" {}
variable "location" {}
variable "sql_admin_username" {}
variable "sql_admin_password" {}
variable "db_name" {}
variable "start_ip_address_allow_azure" {
    default = [ "0.0.0.0"]
}
variable "end_ip_address_allow_azure" {
    default = [ "0.0.0.0"]
}
variable "start_ip_address_localip_address" {}
variable "end_ip_address_localip_address" {}