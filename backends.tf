terraform {
  cloud {
    organization = "mbrown-demo-test"

    workspaces {
      name = "mb-dev"
    }
  }
}