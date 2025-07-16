variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "langfuse"
}

variable "domain" {
  description = "Domain name used for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westeurope"
}

variable "virtual_network_address_prefix" {
  type        = string
  description = "VNET address prefix."
  default     = "10.224.0.0/12"
}

variable "aks_subnet_address_prefix" {
  description = "Subnet address prefix."
  type        = string
  default     = "10.224.0.0/16"
}

variable "app_gateway_subnet_address_prefix" {
  type        = string
  description = "Subnet address prefix."
  default     = "10.225.0.0/16"
}

variable "db_subnet_address_prefix" {
  description = "Subnet address prefix."
  type        = string
  default     = "10.226.0.0/24"
}

variable "redis_subnet_address_prefix" {
  description = "Subnet address prefix."
  type        = string
  default     = "10.226.1.0/24"
}

variable "storage_subnet_address_prefix" {
  description = "Subnet address prefix."
  type        = string
  default     = "10.226.2.0/24"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.32"
}

variable "aks_service_cidr" {
  type        = string
  description = "The Network Range used by the Kubernetes service."
  default     = "192.168.0.0/20"
}

variable "aks_dns_service_ip" {
  type        = string
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns)."
  default     = "192.168.0.10"
}

variable "use_encryption_key" {
  description = "Whether or not to use an Encryption key for LLM API credential and integration credential store"
  type        = bool
  default     = true
}

variable "node_pool_vm_size" {
  description = "VM size for AKS node pool"
  type        = string
  default     = "Standard_D8s_v6"
}

variable "node_pool_min_count" {
  description = "Minimum number of nodes in the AKS node pool"
  type        = number
  default     = 2
}

variable "node_pool_max_count" {
  description = "Maximum number of nodes in the AKS node pool"
  type        = number
  default     = 10
}

variable "postgres_instance_count" {
  description = "Number of PostgreSQL instances to create"
  type        = number
  default     = 2 # Default to 2 instances for high availability
}

variable "postgres_ha_mode" {
  description = "HA Mode to use for Postgres. Ensure this is supported in your region https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/overview#azure-regions"
  type        = string
  default     = "SameZone"
}

variable "postgres_sku_name" {
  description = "SKU name for Azure Database for PostgreSQL"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_storage_mb" {
  description = "Maximum storage size in MB for PostgreSQL"
  type        = number
  default     = 32768
}

variable "redis_sku_name" {
  description = "SKU name for Azure Cache for Redis"
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "Cache family for Azure Cache for Redis"
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Capacity of Azure Cache for Redis"
  type        = number
  default     = 1
}

variable "app_gateway_capacity" {
  description = "Capacity for the Application Gateway"
  type        = number
  default     = 1
}

variable "use_ddos_protection" {
  description = "Wheter or not to use a DDoS protection plan"
  type        = bool
  default     = true
}

variable "langfuse_helm_chart_version" {
  description = "Version of the Langfuse Helm chart to deploy"
  type        = string
  default     = "1.3.1"
}

variable "add_ssl_certificate_annotation" {
  description = <<EOT
Whether to inject the `appgw.ingress.kubernetes.io/appgw-ssl-certificate` annotation in the Helm chart.

Set to false if you're using cert-manager and want to use a K8s TLS secret (referenced via `tls.secretName`)
instead of a Key Vault certificate uploaded to Application Gateway.

If false, the module will omit the annotation, allowing AGIC to manage TLS cert binding from the K8s secret.
EOT
  type        = bool
  default     = true
}

variable "tls_secret_name" {
  description = "The TLS secret name for ingress TLS binding"
  type        = string
  default     = "langfuse-tls-secret"
}
