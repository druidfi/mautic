variable "REPO_BASE" {
  default = "druidfi/mautic"
}

group "default" {
  targets = ["mautic-variants"]
}

group "mautic-variants" {
  targets = [
      #"mautic-71",
      #"mautic-71-dxp",
      "mautic-72",
      "mautic-72-dxp",
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
  # Optional GitHub token for Composer, read from $GITHUB_TOKEN if set (see Dockerfile). Not
  # required -- the secret is simply empty and unused when the env var isn't set.
  secret = ["id=github_token,env=GITHUB_TOKEN"]
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
        "${REPO_BASE}:7.1",
        "${REPO_BASE}:7.1.3",
    ]
}

target "mautic-71-dxp" {
    inherits = ["mautic-71"]
    target = "mautic_dxp_71"
    tags = [
        "${REPO_BASE}-dxp:7.1",
        "${REPO_BASE}-dxp:7.1.3",
    ]
}

target "mautic-72" {
    inherits = ["common"]
    args = {
    }
    contexts = {
        mautic_upstream = "docker-image://mautic/mautic:7.2.0-apache"
    }
    target = "mautic_base_72"
    tags = [
        "${REPO_BASE}:7",
        "${REPO_BASE}:7.2",
        "${REPO_BASE}:7.2.0",
    ]
}

target "mautic-72-dxp" {
    inherits = ["mautic-72"]
    target = "mautic_dxp_72"
    tags = [
        "${REPO_BASE}-dxp:7",
        "${REPO_BASE}-dxp:7.2",
        "${REPO_BASE}-dxp:7.2.0",
    ]
}
