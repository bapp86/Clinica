variable "aws_region" {
  default = "us-east-1"
}

variable "iniciales" {
  description = "BRYANJUAN"
  type        = string
  default     = "BPyJC" 
}

variable "tags" {
  default = {
    Environment = "EFT-Evaluacion"
    Project     = "SanaVI"
  }
}
