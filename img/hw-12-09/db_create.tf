terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.cloud_access_token
  cloud_id  = var.cloud_access_cloud_id
  folder_id = var.cloud_access_folder_id
  zone      = "ru-central1-c"
}

resource "yandex_mdb_postgresql_cluster" "mycluster" {
  name                = "mycluster"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.mynet.id
  security_group_ids  = [ yandex_vpc_security_group.pgsql-sg.id ]
  deletion_protection = false

  config {
    version = 14
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = "10"
    }
  }

  host {
    zone      = "ru-central1-a"
    name      = "mypg-host-a"
    subnet_id = yandex_vpc_subnet.mysubnet-a.id
  }

  host {
    zone      = "ru-central1-b"
    name      = "mypg-host-b"
    subnet_id = yandex_vpc_subnet.mysubnet-b.id
  }
}

resource "yandex_mdb_postgresql_database" "db1" {
  cluster_id = yandex_mdb_postgresql_cluster.mycluster.id
  name       = "db1"
  owner      = "isupov"
  depends_on = [
    yandex_mdb_postgresql_user.isupov
  ]
}

resource "yandex_mdb_postgresql_user" "isupov" {
  cluster_id = yandex_mdb_postgresql_cluster.mycluster.id
  name       = "isupov"
  password   = "12345678"
}    

resource "yandex_vpc_network" "mynet" {
  name = "mynet"
}

resource "yandex_vpc_subnet" "mysubnet-a" {
  name           = "mysubnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

resource "yandex_vpc_subnet" "mysubnet-b" {
  name           = "mysubnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.6.0.0/24"]
}


resource "yandex_vpc_security_group" "pgsql-sg" {
  name       = "pgsql-sg"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    description    = "PostgreSQL"
    port           = 6432
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}
