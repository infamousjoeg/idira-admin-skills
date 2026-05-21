terraform {
  required_version = ">= 1.5"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.3"
    }
  }
}
