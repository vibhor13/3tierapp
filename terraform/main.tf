terraform {
  required_version = "0.14.10"
}
provider "google" {
  project = var.project
}

// Create GKE network and secondary ranges
module "gcp-network" {
  source = "terraform-google-modules/network/google"
  version = "~> 3.1"
  project_id = var.project
  network_name = var.network
  subnets = [{
    subnet_name = var.subnetwork
    subnet_ip = "10.0.0.0/17"
    subnet_region = var.region
    },
    {
     subnet_name = var.subnet_useast
     subnet_ip = "10.1.0.0/17"
     subnet_region = "us-east1"
    }]
  secondary_ranges = {
    "${var.subnetwork}" = [{
      range_name = var.ip_range_pods
      ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name = var.ip_range_services
        ip_cidr_range = "192.168.64.0/18"
      }]
  }
}

// Create GKE cluster
module "gke_cluster" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id = var.project
  region = var.region
  regional = true
  zones = ["us-central1-a","us-central1-b"]
  name = "node-3tier-app-prod"
  depends_on = [module.gcp-network.subnets_secondary_ranges]
  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  network = var.network
  subnetwork = var.subnetwork
  enable_private_endpoint = true
  master_authorized_networks = [{cidr_block=var.private_ip_class_a,display_name="class_a"}
                               ,{cidr_block=var.private_ip_class_c,display_name="class_c"}
                               ,{cidr_block=var.private_ip_class_b,display_name="class_b"}]
  enable_private_nodes = false
  ip_range_pods = var.ip_range_pods
  ip_range_services = var.ip_range_services
  create_service_account = true
  master_ipv4_cidr_block = "172.16.0.32/28"
  remove_default_node_pool = true
  node_pools = [{
    initial_node_count = 1
    name = "primary-node-pool"
    machine_type = "e2-standard-4"
    max_count = 20
    local_ssd_count = 0
    disk_size_gb = 100
    disk_type = "pd-standard"
    image_type = "COS"
    auto_repair = true
    auto_upgrade = false
    preemptible = false
  }
  ]
  horizontal_pod_autoscaling = true
  cluster_autoscaling = {
      enabled       = true
      min_cpu_cores = 8   // Update cores to required
      max_cpu_cores = 50
      min_memory_gb = 12
      max_memory_gb = 40
  }
}

// Create static public ip address for bastion host

  resource "google_compute_address" "static" {
  name = "bastion-host"
  region = "us-east1"
}

// Create bastion host
resource "google_compute_instance" "gke-network" {
  machine_type = "e2-highcpu-4"
  depends_on = [module.gcp-network.subnets_secondary_ranges]
  name = "bastion"
  zone = "us-east1-b"
  boot_disk {
    initialize_params {
//      image     =  "ubuntu-1804-bionic-v20210412"
      image = "jenkins"
      size = "100"
    }
  }
  network_interface {
    subnetwork = var.subnet_useast
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = "sudo snap install kubectl --classic"
}

// Create firewall rule to allow ssh from all private address to bastion host
resource "google_compute_firewall" "gke_network" {
  name = "gke-network-firewall"
  depends_on = [module.gcp-network.subnets_secondary_ranges]
  network = var.network
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = [var.private_ip_class_a,var.private_ip_class_b,var.private_ip_class_c]  //Add your ip address from where ssh connection to bastion host will be made .
}

// Create private IP address range for postgres service  ref : https://cloud.google.com/vpc/docs/configure-private-services-access?authuser=1&_ga=2.65635950.-1385654497.1603299511#allocating-range
resource "google_compute_global_address" "private_ip_address" {
  name          = "pg-pvt-address"
  purpose       = "VPC_PEERING"
  depends_on = [module.gcp-network.subnets_secondary_ranges]
  address_type  = "INTERNAL"
  prefix_length = 24
  address = "10.126.0.0"
  network       = var.network
}

// Service networking connection
resource "google_service_networking_connection" "private_vpc_peering" {
  network = var.network
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  service = "servicenetworking.googleapis.com"
}

// Create CLOUD SQL Postgres DB
resource "google_sql_database" "database" {
  instance = google_sql_database_instance.instance.name
  name = "toptal"
}

// Create DB instance
resource "google_sql_database_instance" "instance" {
  provider = google-beta
  name = "node-webapp-57" // ***** Remember to change the name if redeploying, Google doesn't allow reusing name for 1 week after destruction ******
  region = "us-central1"
  project = var.project
  database_version = "POSTGRES_13"
  depends_on = [module.gcp-network.subnets_secondary_ranges,google_service_networking_connection.private_vpc_peering]
  settings {
    tier = "db-custom-1-3840"  // Format is db-custom-<CPU>-<RAM in MB min 3840>
    availability_type = "REGIONAL"
    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
    ip_configuration {
      ipv4_enabled = false
      private_network = "projects/${var.project}/global/networks/${var.network}"
    }
  }
  deletion_protection = false
}

// Create DB user
resource "google_sql_user" "db_user" {
  name= var.dbuser
  instance = google_sql_database_instance.instance.name
  password = "toptal"
}
// output the IP address
output "postgres_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}
