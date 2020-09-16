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
  region        = var.region
  network       = google_compute_network.vpc.id
}

##firewall rules
resource "google_compute_firewall" "internal_all" {
  name    = "${var.name}-internal-fwr"
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

resource "google_compute_firewall" "external" {
  name    = "${var.name}-external-fwr"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "22", "8080"]
  }
  source_ranges = ["0.0.0.0/0"]
  description   = "rules for external connections, allows http and ssh"
}


resource "google_compute_address" "internal_server_address" {
  name         = "${var.name}-server-address"
  subnetwork   = google_compute_subnetwork.public.id
  address_type = "INTERNAL"
  region       = var.region
}

#create instance datadog server
resource "google_compute_instance" "server" {
    name = "${var.name}-agent"
    zone = var.zone
    machine_type = "n1-standard-1"
  boot_disk {
    initialize_params {
      image = var.image
      size = var.size
      type = var.disk_type
    }
  }
  metadata_startup_script = templatefile("datadog_agent_provision.sh", {web_instance_name = "${var.web_instance_name}", 
  api_key = "${var.api_key}"})
  network_interface {
    network = google_compute_network.vpc.name
    network_ip = google_compute_address.internal_server_address.address
    subnetwork = google_compute_subnetwork.public.name
    access_config {
    }
  }
}

