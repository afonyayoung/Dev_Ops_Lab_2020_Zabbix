#do 
#export GOOGLE_CLOUD_KEYFILE_JSON=/path/to/file
#before apply
provider "google" {
  project       = var.project
  region        = var.region
}

#Network settings
resource "google_compute_network" "vpc" {
  name          = "${var.name}-vpc"
  auto_create_subnetworks = false
}
##subnets
resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  ip_cidr_range = "10.1.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc.id
}

##firewall rules
resource "google_compute_firewall" "internal_all" {
  name    = "internal-fwr"
  network = google_compute_network.vpc.name
  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }
  allow {
    ports    = ["0-65535"]
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.1.1.0/24"]
}

resource "google_compute_firewall" "internal" {
  name    = "external-fwr"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }
  source_ranges = ["0.0.0.0/0"]
  description   = "rules for external connections, allows http and ssh"
}


resource "google_compute_address" "internal_ldap_server_address" {
  name         = "ldap-server-address"
  subnetwork   = google_compute_subnetwork.public.id
  address_type = "INTERNAL"
  region       = var.region
}

#create instance ldap server
resource "google_compute_instance" "ldap_server" {
    name = "${var.name}-server"
    zone = var.zone
    machine_type = "n1-standard-1"
    description = "Centos 7 with installed nginx"
  boot_disk {
    initialize_params {
      image = var.image
      size = var.size
      type = var.disk_type
    }
  }
  metadata_startup_script = templatefile("provision.sh", {name = "${var.name}"})
  network_interface {
    network = google_compute_network.vpc.name
    network_ip = google_compute_address.internal_ldap_server_address.address
    subnetwork = google_compute_subnetwork.public.name
    access_config {
    }
  }
}
#create instance ldap client
resource "google_compute_instance" "ldap_client" {
    depends_on = [google_compute_instance.ldap_server]
    name = "${var.name}-client"
    zone = var.zone
    machine_type = "n1-standard-1"
    description = "Centos 7 with installed nginx"
  boot_disk {
    initialize_params {
      image = var.image
      size = var.size
      type = var.disk_type
    }
  }
  metadata_startup_script = templatefile("ldap_client.sh", {server_ip = "${google_compute_address.internal_ldap_server_address.address}"})
  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.public.name
    access_config {
    }
  }
}
