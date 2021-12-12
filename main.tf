resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_config_map" "postgres-init" {
  metadata {
    labels = {
      app = "demo"
    }
    name      = "demo"
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
          #          command = ["bash", "-c", "while true; do sleep 10s; done"]
          env {
            name  = "POSTGRES_USER"
            value = "root"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "root"
          }
          image = "postgres:11.14-bullseye"
          name  = "postgres"
          port {
            container_port = 5432
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
          volume_mount {
            name       = "postgres-init"
            mount_path = "/docker-entrypoint-initdb.d"
          }
          volume_mount {
            name       = "mysql-dump"
            mount_path = "/dump"
          }
        }
        container {
          env {
            name  = "DATASOURCE_URL"
            value = "jdbc:postgresql://localhost/test"
          }
          env {
            name  = "DATASOURCE_USERNAME"
            value = "root"
          }
          env {
            name  = "DATASOURCE_PASSWORD"
            value = "root"
          }
          image             = "nerfdog/springboot-rest-mysql:0.0.3"
          image_pull_policy = "Always" # XXX
          name              = "springboot-rest-mysql"
          port {
            container_port = 8080
          }
        }
        volume {
          name = "postgres-data"
          #          host_path {
          #            path = "/var/lib/postgres_springboot_AAAB"
          #          }
          empty_dir {} # XXX
        }
        volume {
          name = "postgres-init"
          config_map {
            name = kubernetes_config_map.postgres-init.metadata.0.name
          }
        }
        volume {
          name = "mysql-dump"
          host_path {
            path = "/var/lib/mysql_springboot_dump"
          }
        }
      }
    }
  }
}
