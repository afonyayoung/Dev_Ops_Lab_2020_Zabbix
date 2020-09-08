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
resource "google_compute_firewall" "external" {
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
  address      = "10.1.1.2"
  region       = var.region
}
#create instance
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
  metadata = {
    ssh-keys = "alexey_afanasenko:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQClM2ALhguKBQd+wZ1TynkCAcXVU5DJoqZZ79vQMNgT1dpRCxbVj0gA0IRLkRXgLsRlIz0effqqahBtUekuIDaSi/D7+vAJ5n59jUb7u5C3ENLCApsdYjCWE7xdMJDmtZ1bbIQ3xv9Mf8o2HRnLFZZr7c5PG5Ow27JJuUWG8dxuCDoeRSq2znv5Nx4MHJ7MIaxNcexyZW43ukOD2DLyQZPfER4Kp3XPRNBTIP3cHFZTKLQQfV+PdlfjH/0lMJEHyyy6V636PVj68BlgXIERtFAvXvv3RLxF5LWwYPDVAPIIOrm49OWAx/C2NK77lTiD0U24blsXNizeE6wBCaeDPzpZ/PUcVTS40/nJ9cHGJ93C0FyCgba2kYHQ6N21jS9I9tOYroE5mWT0ucuN/yGtFz7WSUTxTLojPCZOms3uWJc363R9K5ZfDceJsFOFdGRxppGyEdaSmPO57aMdIFtgMGl2ZHgtrf0kOitufDIg7sMNUc7mKmGNtNX0RiYEC6w94wj1/zZznvTec6qA6qzl6DHDlqC65wp5xzf9rLSnS28qXTdIUtM/xjUbq1GnByM6PdofYCt9xKSNWL3p7Q== alexey_afanasenko@epam.com"
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