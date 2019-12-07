variable "region" {
  description = "リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "name" {
  description = "EC2の名前"
  type        = string
}

variable "amis" {
  type = "map"
  description = "EC2のAMI : リージョンによって指定できるAMIが異なる"
  default = {
   "ap-northeast-1" = "ami-785c491f"
   "us-east-1"      = "ami-abc123"
  }
}

variable "instance_type" {
  description = "EC2のインスタンスタイプ"
  type        = string
  default     = "t2.micro"
}

//--------- Security Group ----------- //

variable "security_group_name" {
  description = "セキュリティグループの名前"
  type        = string
}