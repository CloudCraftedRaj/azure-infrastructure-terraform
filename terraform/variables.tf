variable "sql_admin_username" { 
    type = string 
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

# optional: let Terraform auto-detect your public IP for firewall
variable "my_public_ip" {
  type        = string
  description = "Your public IPv4 address (example: 1.2.3.4)"
}