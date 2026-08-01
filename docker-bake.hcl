variable "REPO_BASE" {
  default = "druidfi/mautic"
}

group "default" {
  targets = ["mautic-variants"]
}

group "mautic-variants" {
  targets = [
      "mautic-71",
      "mautic-71-dxp",
  ]
}

target "common" {
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.url" = "https://github.com/druidfi/mautic"
    "org.opencontainers.image.source" = "https://github.com/druidfi/mautic"
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.vendor" = "Druid Oy"
    "org.opencontainers.image.created" = timestamp()
  }
}

#
# MAUTIC
#

target "mautic-71" {
    inherits = ["common"]
    args = {
    }
    contexts = {
        mautic_upstream = "docker-image://mautic/mautic:7.1.3-apache"
    }
    target = "mautic_base_71"
    tags = [
        "${REPO_BASE}:7",
        "${REPO_BASE}:7.1",
        "${REPO_BASE}:7.1.3",
    ]
}

target "mautic-71-dxp" {
    inherits = ["mautic-71"]
    target = "mautic_dxp_71"
    tags = [
        "${REPO_BASE}-dxp:7",
        "${REPO_BASE}-dxp:7.1",
        "${REPO_BASE}-dxp:7.1.3",
    ]
}
