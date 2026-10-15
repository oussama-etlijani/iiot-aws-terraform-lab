provider "aws" {
  region  = "eu-central-1"
  profile = "iiot-lab"

  default_tags {
    tags = {
      project = "iiot-lab",
      owner   = "oussama",
      env     = "bootstrap"
    }
  }
}