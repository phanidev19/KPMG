variable "aws_region" {
  default = "us-east-1"
}

variable "env" {
  default = "kpmg-challenge"
}

variable "instance_type" {
  default = "t3.micro"
}
variable "ssh_key" {
  default = "kpmg-keypair"
}

variable "ec2_count" {
  default = 2
}
variable "sg_id" {
    default = "sg-0fbe8f9140330526c"
}

variable "ami_id" {
    default = "ami-0b0af3577fe5e3532"
}

variable "db_engine_version" {
  default = "11.8"
}
variable "db_port" {
  default = "5432"
}

variable "no_of_db_instances" {
  default = 2
}
variable "rds_instance_type" {
  default = "db.r6g.large"
}

variable "db_name" {
  default = "kpmgchallenge"
}
variable "db_username" {
  default = "kpmgdbuser"
}
variable "db_password" {
  default = "KpMGdbUsrPwd321"
}
variable "engine" {
  default = "aurora-postgresql"
}
