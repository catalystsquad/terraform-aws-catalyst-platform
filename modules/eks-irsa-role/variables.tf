# required input variables
variable "role_name" {
  description = "Name of IAM role"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  type        = string
}

variable "eks_identity_oidc_url" {
  description = "EKS cluster OIDC provider URL"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of service account that will assume the IAM role"
  type        = string
}

variable "service_account" {
  description = "Kubernetes servicea ccount name that will assume the IAM role"
  type        = string
}

# optional input variables
variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default     = {}
}

variable "enable_policy" {
  description = "Whether to manage an IAM policy and attach it to the IRSA role"
  type        = bool
  default     = false
}

variable "policy_document" {
  description = "IAM policy to add to the IAM role"
  type        = string
  default     = ""
}

variable "policy_name" {
  description = "Optional name of policy to create, defaults to the role name if not supplied"
  type        = string
  default     = ""
}

variable "policy_description" {
  description = "Optional description of policy to create, defaults to the role description if not supplied"
  type        = string
  default     = ""
}

variable "extra_assume_role_policy_statements" {
  description = "A list of extra IAM policy statements to add to the assume role policy"
  type = list(object({
    actions       = optional(list(string), null)
    effect        = optional(string, null)
    not_actions   = optional(list(string), null)
    not_resources = optional(list(string), null)
    resources     = optional(list(string), null)
    sid           = optional(string, null)

    conditions = optional(list(object({
      test     = optional(string, null)
      values   = optional(list(string), null)
      variable = optional(string, null)
    })), [])

    not_principals = optional(list(object({
      identifiers = optional(list(string), null)
      type        = optional(string, null)
    })), [])

    principals = optional(list(object({
      identifiers = optional(list(string), null)
      type        = optional(string, null)
    })), [])
  }))
  default = []
}
