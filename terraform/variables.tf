# Proxmox Variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.1.233:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox username"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "proxmox-node1"
}

# Vault Variables
variable "vault_address" {
  description = "Vault server address"
  type        = string
  default     = "http://localhost:8200"
}

variable "vault_token" {
  description = "Vault root token"
  type        = string
  sensitive   = true
}

# SSH Variables
variable "ssh_public_key" {
  description = "SSH public key for VMs"
  type        = string
}

# Application Secrets
variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

variable "tmdb_api_key" {
  description = "TMDB API key for TV Dashboard"
  type        = string
  sensitive   = true
}
