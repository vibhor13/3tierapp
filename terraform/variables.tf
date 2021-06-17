variable "project" {
  description = "Main project in GCP "
  default = "dynamic-concept-305518"
}
variable "region" {
  description = "Region for k8's network"
  default = "us-central1"
}
variable "network" {
  description = "Network to add gke cluster in ."
  default = "gke-network"
}
variable "subnet_useast" {
  description = "subnet is us-east1"
  default = "gke-us-east"
}
variable "subnetwork" {
  description = "subnet created for the gke cluster"
  default = "gke-subnet"
}
variable "ip_range_pods" {
  description = "secondry ip range for pods"
  default = "ip-range-pods"
}
variable "ip_range_services" {
  description = "secondry ip range for services"
  default = "ip-range-svc"
}
variable "private_ip_class_a" {
  description = "Class A private IP address"
  default = "10.0.0.0/8"
}
variable "private_ip_class_b" {
  description = "Class B private IP addresses"
  default = "172.16.0.0/12"
}
variable "private_ip_class_c" {
  description = "Class C private IP addresses"
  default = "192.168.0.0/16"
}
variable "dbuser" {
  description = "Name of the database user"
  default = "toptal"
}