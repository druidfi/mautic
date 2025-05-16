variable "REPO_BASE" {
  default = "druidfi/mautic"
}

group "default" {
  targets = ["mautic-variants"]
}

group "mautic-variants" {
  targets = ["mautic-5", "mautic-5-dxp", "mautic-6", "mautic-6-dxp"]
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
    mautic_upstream = "docker-image://mautic/mautic:5.2.5-apache"
  }
  target = "mautic_base_5"
  tags = [
    "${REPO_BASE}:5",
    "${REPO_BASE}:5.2",
    "${REPO_BASE}:5.2.5"
  ]
}

target "mautic-5-dxp" {
  inherits = ["mautic-5"]
  target = "mautic_dxp_5"
  tags = [
    "${REPO_BASE}-dxp:5",
    "${REPO_BASE}-dxp:5.2",
    "${REPO_BASE}-dxp:5.2.5"
  ]
}

#
# MAUTIC 6
#

target "mautic-6" {
  inherits = ["common"]
  args = {
  }
  contexts = {
    mautic_upstream = "docker-image://mautic/mautic:6.0.1-apache"
  }
  target = "mautic_base_6"
  tags = [
    "${REPO_BASE}:6",
    "${REPO_BASE}:6.0",
    "${REPO_BASE}:6.0.1"
  ]
}

target "mautic-6-dxp" {
  inherits = ["mautic-6"]
  target = "mautic_dxp_6"
  tags = [
    "${REPO_BASE}-dxp:6",
    "${REPO_BASE}-dxp:6.0",
    "${REPO_BASE}-dxp:6.0.1"
  ]
}
