variable "bucket_suffixes" {
  type    = list(string)
  default = ["app1", "app2", "logs", "backup"]
}

variable "instance_ami" {
  type        = string
  description = "AMI ID for EC2"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "s3_prefix" {
  type = string
}

variable "db_name" {
  type        = string
  description = "Database name"
}
variable "db_username" {
  type        = string
  description = "Master username"
}
variable "db_password" {
  type        = string
  description = "Master password"
  sensitive   = true
}