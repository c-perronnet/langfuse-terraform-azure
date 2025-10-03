locals {
  langfuse_values   = <<EOT
langfuse:
  salt:
    secretKeyRef:
      name: langfuse
      key: salt
  nextauth:
    url: "https://${var.domain}"
    secret:
      secretKeyRef:
        name: langfuse
        key: nextauth-secret
postgresql:
  deploy: false
  host: ${azurerm_private_endpoint.postgres.private_service_connection[0].private_ip_address}:5432
  auth:
    username: ${azurerm_postgresql_flexible_server.this.administrator_login}
    database: langfuse
    existingSecret: langfuse
    secretKeys:
      userPasswordKey: postgres-password
clickhouse:
  auth:
    existingSecret: langfuse
    existingSecretKey: clickhouse-password
redis:
  deploy: false
  host: ${azurerm_redis_cache.this.name}.redis.cache.windows.net
  port: 6380
  tls:
    enabled: true
  auth:
    existingSecret: langfuse
    existingSecretPasswordKey: redis-password
s3:
  deploy: false
  endpoint: https://${azurerm_storage_account.this.name}.blob.core.windows.net
  bucket: ${azurerm_storage_container.this.name}
  region: ${azurerm_storage_account.this.location}
  accessKeyId:
    value: ${azurerm_storage_account.this.name}
  secretAccessKey:
    secretKeyRef:
      name: ${kubernetes_secret.langfuse.metadata[0].name}
      key: storage-access-key
  forcePathStyle: true
  eventUpload:
    prefix: "events/"
  batchExport:
    prefix: "exports/"
  mediaUpload:
    prefix: "media/"
  additionalEnv:
  - name: AUTH_DISABLE_SIGNUP
    value: "false"
EOT
  encryption_values = var.use_encryption_key == false ? "" : <<EOT
langfuse:
  encryptionKey:
    secretKeyRef:
      name: ${kubernetes_secret.langfuse.metadata[0].name}
      key: encryption-key
EOT

  sso_values = <<EOT
langfuse:
  additionalEnv:
  - name: AUTH_GOOGLE_CLIENT_ID
    valueFrom:
      secretKeyRef:
        name: ${kubernetes_secret.langfuse.metadata[0].name}
        key: google-client-id
  - name: AUTH_GOOGLE_CLIENT_SECRET
    valueFrom:
      secretKeyRef:
        name: ${kubernetes_secret.langfuse.metadata[0].name}
        key: google-client-secret
  - name: AUTH_GOOGLE_ALLOWED_DOMAINS
    value: "${var.auth_domains_with_sso_enforcement}"
  - name: AUTH_DOMAINS_WITH_SSO_ENFORCEMENT
    value: "${var.auth_domains_with_sso_enforcement}"
  - name: AUTH_GOOGLE_ALLOW_ACCOUNT_LINKING
    value: "true"
  - name: AUTH_DISABLE_USERNAME_PASSWORD
    value: "true"
  - name: LANGFUSE_USE_AZURE_BLOB
    value: "true"
EOT
  additional_env_values = length(var.additional_env) == 0 ? "" : <<EOT
langfuse:
  additionalEnv:
%{for env in var.additional_env}
  - name: ${env.name}
%{if env.value != null}
    value: "${env.value}"
%{endif}
%{if env.valueFrom != null}
    valueFrom:
%{if env.valueFrom.secretKeyRef != null}
      secretKeyRef:
        name: ${env.valueFrom.secretKeyRef.name}
        key: ${env.valueFrom.secretKeyRef.key}
%{endif}
%{if env.valueFrom.configMapKeyRef != null}
      configMapKeyRef:
        name: ${env.valueFrom.configMapKeyRef.name}
        key: ${env.valueFrom.configMapKeyRef.key}
%{endif}
%{endif}
%{endfor}
EOT
  additional_env_values = length(var.additional_env) == 0 ? "" : <<EOT
langfuse:
  additionalEnv:
%{for env in var.additional_env}
  - name: ${env.name}
%{if env.value != null}
    value: "${env.value}"
%{endif}
%{if env.valueFrom != null}
    valueFrom:
%{if env.valueFrom.secretKeyRef != null}
      secretKeyRef:
        name: ${env.valueFrom.secretKeyRef.name}
        key: ${env.valueFrom.secretKeyRef.key}
%{endif}
%{if env.valueFrom.configMapKeyRef != null}
      configMapKeyRef:
        name: ${env.valueFrom.configMapKeyRef.name}
        key: ${env.valueFrom.configMapKeyRef.key}
%{endif}
%{endif}
%{endfor}
EOT
  additional_env_values = length(var.additional_env) == 0 ? "" : <<EOT
langfuse:
  additionalEnv:
%{for env in var.additional_env}
  - name: ${env.name}
%{if env.value != null}
    value: "${env.value}"
%{endif}
%{if env.valueFrom != null}
    valueFrom:
%{if env.valueFrom.secretKeyRef != null}
      secretKeyRef:
        name: ${env.valueFrom.secretKeyRef.name}
        key: ${env.valueFrom.secretKeyRef.key}
%{endif}
%{if env.valueFrom.configMapKeyRef != null}
      configMapKeyRef:
        name: ${env.valueFrom.configMapKeyRef.name}
        key: ${env.valueFrom.configMapKeyRef.key}
%{endif}
%{endif}
%{endfor}
EOT
}

resource "kubernetes_namespace" "langfuse" {
  metadata {
    name = "langfuse"
  }
}

resource "random_bytes" "salt" {
  # Should be at least 256 bits (32 bytes): https://langfuse.com/self-hosting/configuration#core-infrastructure-settings ~> SALT
  length = 32
}

resource "random_bytes" "nextauth_secret" {
  # Should be at least 256 bits (32 bytes): https://langfuse.com/self-hosting/configuration#core-infrastructure-settings ~> NEXTAUTH_SECRET
  length = 32
}

resource "random_bytes" "encryption_key" {
  count = var.use_encryption_key ? 1 : 0
  # Must be exactly 256 bits (32 bytes): https://langfuse.com/self-hosting/configuration#core-infrastructure-settings ~> ENCRYPTION_KEY
  length = 32
}

resource "kubernetes_secret" "langfuse" {
  metadata {
    name      = "langfuse"
    namespace = "langfuse"
  }

  data = {
    "redis-password"                     = azurerm_redis_cache.this.primary_access_key
    "postgres-password"                  = azurerm_postgresql_flexible_server.this.administrator_password
    "storage-access-key"                 = azurerm_storage_account.this.primary_access_key
    "salt"                               = random_bytes.salt.base64
    "nextauth-secret"                    = random_bytes.nextauth_secret.base64
    "clickhouse-password"                = random_password.clickhouse_password.result
    "encryption-key"                     = var.use_encryption_key ? random_bytes.encryption_key[0].hex : ""
    "google-client-id"        = var.google_client_id
    "google-client-secret"    = var.google_client_secret
  }
}

resource "helm_release" "langfuse" {
  name             = "langfuse"
  repository       = "https://langfuse.github.io/langfuse-k8s"
  version          = var.langfuse_helm_chart_version
  chart            = "langfuse"
  namespace        = "langfuse"
  create_namespace = true

  values = [
    local.langfuse_values,
    local.ingress_values,
    local.encryption_values,
    local.sso_values,
    local.additional_env_values
  ]
}
