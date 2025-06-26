resource "kubernetes_namespace" "weather_app" {
  metadata {
    name = "weather-app"
  }
}

resource "kubernetes_deployment" "weather_app" {
  depends_on = [aws_ecr_repository.weather_app]
  
  metadata {
    name      = "weather-app"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
    labels = {
      app = "weather-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "weather-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "weather-app"
        }
      }

      spec {
        container {
          image = "${aws_ecr_repository.weather_app.repository_url}:latest"
          name  = "weather-app"
          image_pull_policy = "Always"

          port {
            container_port = 4000
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 4000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 4000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "weather_app" {
  metadata {
    name      = "weather-app-service"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  spec {
    selector = {
      app = "weather-app"
    }

    port {
      port        = 80
      target_port = 4000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "weather_app" {
  metadata {
    name      = "weather-app-ingress"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
    }
  }

  spec {
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service.weather_app.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}