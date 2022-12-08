# Copyright 2022 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.41.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.0"
    }
  }
}