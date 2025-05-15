variable "REPO_BASE" {
  default = "druidfi/mautic"
}

group "default" {
  targets = ["mautic-variants"]
}

group "mautic-variants" {
  targets = ["mautic-5", "mautic-5-dxp"]
}

target "common" {
  #context = "./mautic"
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.url" = "https://github.com/druidfi/mautic"
    "org.opencontainers.image.source" = "https://github.com/druidfi/mautic"
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.vendor" = "Druid Oy"
    "org.opencontainers.image.created" = "${timestamp()}"
  }
}

#
# MAUTIC
#

target "mautic-5" {
  inherits = ["common"]
  args = {
  }
  contexts = {
    mautic_upstream = "docker-image://mautic/mautic:5.2.4-apache"
  }
  target = "mautic_base_5"
  tags = [
    "${REPO_BASE}:5",
    "${REPO_BASE}:5.2",
    "${REPO_BASE}:5.2.4"
  ]
}

target "mautic-5-dxp" {
  inherits = ["mautic-5"]
  target = "mautic_dxp_5"
  tags = [
    "${REPO_BASE}-dxp:5",
    "${REPO_BASE}-dxp:5.2",
    "${REPO_BASE}-dxp:5.2.4"
  ]
}
