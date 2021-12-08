resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_config_map" "demo" {
  metadata {
    name = "demo"
    namespace = kubernetes_namespace.demo.metadata.0.name
  }

  data = {
    "init.sql" = "${file("${path.module}/init.sql")}"
  }
}

resource "kubernetes_deployment" "demo" {
  metadata {
    labels = {
      app = "demo"
    }
    name      = "demo"
    namespace = kubernetes_namespace.demo.metadata.0.name
  }
  spec {
    replicas = 1
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app = "demo"
      }
    }
    template {
      metadata {
        labels = {
          app = "demo"
        }
      }
      spec {
        container {
          env {
            name  = "MYSQL_RANDOM_ROOT_PASSWORD"
            value = "yes"
          }
          image = "mysql:8.0.27"
          name  = "mysql"
          port {
            container_port = 3306
          }
          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
          volume_mount {
            name       = "mysql-init"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }
        container {
          image = "nerfdog/springboot-rest-mysql:0.0.2"
          name  = "springboot-rest-mysql"
          port {
            container_port = 8080
          }
        }
        volume {
          name = "mysql-data"
          host_path {
            path = "/var/lib/mysql_springboot"
          }
        }
        volume {
          name = "mysql-init"
          config_map {
            name = kubernetes_config_map.demo.metadata.0.name
          }
        }
      }
    }
  }
}
