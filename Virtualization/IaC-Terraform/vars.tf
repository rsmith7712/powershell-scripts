#=========================#
# vSphere datacenter      #
#=========================#
variable "datacenter" {
  description = "Datacenter to target"
}

variable "cluster" {
  description = "Cluster to target"
}

variable "datastore" {
  description = "Datastore used for the vSphere virtual machines"
}

variable "network" {
  description = "Network used for the vSphere virtual machines"
}

variable "template" {
  description = "Template used to create the vSphere virtual machines"
}

variable "domain" {
  description = "Domain for the vSphere virtual machine"
  default     = "example.com"
}

#================#
#       DNS      #
#================#

variable "dns" {
  description = "DNS for the vSphere virtual machine"
}

#===================#
#  Chef Provisioner #
#===================#

variable "prov_user" {
  description = "Username for provisioning (from the template)"
  default     = "ubuntu"
}

variable "prov_password" {
  description = "Password for provisioning (from the template)"
  default     = "ubuntu"
}

variable "chef_server" {
  description = "Chef Server for managing nodes"
}

variable "policy_group" {
  description = "Chef policy group/Environment"
}

variable "policy" {
  description = "Chef policy"
}

variable "validation_cert" {
  description = "Chef Validation Cert Location"
}

variable "validation_name" {
  description = "Chef Validation Cert Name"
}
