variable "AWS_REGION" {    
    default = "eu-west-1"
}

variable "azs" {
    type = list
    default = ["eu-west-1a", "eu-west-1b"]
}

variable "webservers_ami" {
    default = "ami-0d1bf5b68307103c2"
}

variable "instance_type" {
    default = "t3.medium"
}