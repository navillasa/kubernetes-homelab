resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "k8s" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://10.152.183.1:443"
  disable_iss_validation = true
}

resource "vault_policy" "external_secrets" {
  name = "external-secrets-policy"

  policy = <<EOT
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "external_secrets" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "external-secrets"
  bound_service_account_names      = ["external-secrets-sa"]
  bound_service_account_namespaces = ["tv-dashboard-prod", "tv-dashboard-dev"]
  token_ttl                        = 86400
  token_policies                   = [vault_policy.external_secrets.name]
}

resource "vault_mount" "secret" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV v2 secret engine for homelab"
}

resource "vault_kv_secret_v2" "postgres" {
  mount               = vault_mount.secret.path
  name                = "postgres"
  delete_all_versions = true
  data_json = jsonencode({
    password = var.postgres_password
  })
}

resource "vault_kv_secret_v2" "prod_database" {
  mount               = vault_mount.secret.path
  name                = "prod/database"
  delete_all_versions = true
  data_json = jsonencode({
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
    postgres_db       = var.postgres_db
  })
}

resource "vault_kv_secret_v2" "prod_api" {
  mount               = vault_mount.secret.path
  name                = "prod/api"
  delete_all_versions = true
  data_json = jsonencode({
    tmdb_api_key = var.tmdb_api_key
  })
}

resource "vault_kv_secret_v2" "dev_database" {
  mount               = vault_mount.secret.path
  name                = "dev/database"
  delete_all_versions = true
  data_json = jsonencode({
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
    postgres_db       = var.postgres_db
  })
}

resource "vault_kv_secret_v2" "dev_api" {
  mount               = vault_mount.secret.path
  name                = "dev/api"
  delete_all_versions = true
  data_json = jsonencode({
    tmdb_api_key = var.tmdb_api_key
  })
}
