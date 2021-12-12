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
