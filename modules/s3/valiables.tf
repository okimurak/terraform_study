variable "bucket_name" {
  description = "S3のバケット名"
  type        = string
}

variable "is_versioning" {
  description = "バージョニングするかどうか"
  type        = bool
  default     = true
}

