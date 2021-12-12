resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_config_map" "demo" {
  metadata {
    name      = "demo"
    namespace = kubernetes_namespace.demo.metadata.0.name
  }

  data = {
    "init.sql" = "${file("${path.module}/init.sql")}"
  }
}

resource "kubernetes_config_map" "mysql-config" {
  metadata {
    name      = "mysql-config"
    namespace = kubernetes_namespace.demo.metadata.0.name
  }

  data = {
    "docker.cnf" = "${file("${path.module}/docker.cnf")}"
  }
}

resource "kubernetes_job" "mysqldump" {
  metadata {
    name      = "mysqldump"
    namespace = kubernetes_namespace.demo.metadata.0.name
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          env {
            name  = "MYSQL_ROOT_HOST"
            value = "127.0.0.1"
          }
          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "aaaa"
          }
          name    = "mysql"
          image   = "mysql:8.0.27"
          command = ["gosu", "mysql", "mysqld", "--skip-grant-tables"]
          volume_mount {
            name       = "mysql-config"
            mount_path = "/etc/mysql/conf.d"
          }
          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }
          volume_mount {
            name       = "mysql-dump"
            mount_path = "/dump"
          }
          volume_mount {
            name       = "mysql-run"
            mount_path = "/var/run/mysqld"
          }
        }
        container {
          name  = "mysqldump"
          image = "mysql:8.0.27"

          command = ["bash", "-c",
          "while true; do mysqladmin --host=localhost ping && break || sleep 1s; done; mkdir -p /dump/out && chown mysql:mysql /dump/out && mysqldump --host=localhost --tab /dump/out test && ls -ltrash /dump/out/ && mysqladmin --host=localhost shutdown"]
          volume_mount {
            name       = "mysql-dump"
            mount_path = "/dump"
          }
          volume_mount {
            name       = "mysql-run"
            mount_path = "/var/run/mysqld"
          }
          security_context {
            run_as_user = 0
          }
        }
        volume {
          name = "mysql-config"
          config_map {
            name = kubernetes_config_map.mysql-config.metadata.0.name
          }
        }
        volume {
          name = "mysql-data"
          host_path {
            path = "/var/lib/mysql_springboot"
          }
        }
        volume {
          name = "mysql-dump"
          host_path {
            path = "/var/lib/mysql_springboot_dump"
          }
        }
        volume {
          name = "mysql-run"
          empty_dir {}
        }
        restart_policy = "Never"
      }
    }
  }
}
