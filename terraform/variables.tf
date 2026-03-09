variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "management_ip" {
  description = "Your home IP for SSH — find it at whatismyip.com"
  type        = string
  # No default — must be explicitly provided
  # Never hardcode IPs in version control
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}