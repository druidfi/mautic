variable "REPO_NAME" {
    default = "druidfi/mautic"
}

variable "VERSION" {
    default = "5.0.2"
}

group "default" {
    targets = ["php-81", "php-82"]
}

target "common" {
    platforms = ["linux/amd64", "linux/arm64"]
    context = "."
}

target "php-81" {
    inherits = ["common"]
    args = {
        PHP_VERSION = 8.1
    }
    tags = ["${REPO_NAME}:${VERSION}-php8.1", "${REPO_NAME}:${VERSION}", "${REPO_NAME}:latest"]
}

target "php-82" {
    inherits = ["common"]
    args = {
        PHP_VERSION = 8.2
    }
    tags = ["${REPO_NAME}:${VERSION}-php8.2"]
}
