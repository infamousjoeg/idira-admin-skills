terraform {
  # Note: Terraform 1.5.x has trouble installing cyberark/conjur >= 0.8.x
  # (likely related to provider signing-key metadata). Use Terraform 1.6+ for
  # this module — local installs newer than 1.5.7 install the provider cleanly.
  required_version = ">= 1.6"

  required_providers {
    conjur = {
      source  = "cyberark/conjur"
      version = ">= 0.8.4, < 1.0.0"
    }
  }
}
