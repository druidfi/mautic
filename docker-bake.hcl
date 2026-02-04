variable "REPO_BASE" {
  default = "druidfi/mautic"
}

group "default" {
  targets = ["mautic-variants"]
}

group "mautic-variants" {
  targets = [
      "mautic-5",
      "mautic-5-dxp",
      "mautic-7",
      "mautic-7-dxp",
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

target "mautic-5" {
  inherits = ["common"]
  args = {
  }
  contexts = {
    mautic_upstream = "docker-image://mautic/mautic:5.2.9-apache"
  }
  target = "mautic_base_5"
  tags = [
    "${REPO_BASE}:5",
    "${REPO_BASE}:5.2",
    "${REPO_BASE}:5.2.9",
  ]
}

target "mautic-5-dxp" {
  inherits = ["mautic-5"]
  target = "mautic_dxp_5"
  tags = [
    "${REPO_BASE}-dxp:5",
    "${REPO_BASE}-dxp:5.2",
    "${REPO_BASE}-dxp:5.2.9",
  ]
}

# target "mautic-6" {
#     inherits = ["common"]
#     args = {
#     }
#     contexts = {
#         mautic_upstream = "docker-image://mautic/mautic:6.0.7-apache"
#     }
#     target = "mautic_base_7"
#     tags = [
#         "${REPO_BASE}:6",
#         "${REPO_BASE}:6.0",
#         "${REPO_BASE}:6.0.7",
#     ]
# }

target "mautic-7" {
    inherits = ["common"]
    args = {
    }
    contexts = {
        mautic_upstream = "docker-image://mautic/mautic:7.0.0-apache"
    }
    target = "mautic_base_7"
    tags = [
        "${REPO_BASE}:7",
        "${REPO_BASE}:7.0",
        "${REPO_BASE}:7.0.0",
    ]
}

target "mautic-7-dxp" {
    inherits = ["mautic-7"]
    target = "mautic_dxp_7"
    tags = [
        "${REPO_BASE}-dxp:7",
        "${REPO_BASE}-dxp:7.0",
        "${REPO_BASE}-dxp:7.0.0",
    ]
}
