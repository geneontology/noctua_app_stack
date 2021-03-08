provider "google" {
 credentials = file("~/.google/auth.json")
 project     = "valid-actor-303220"
 region      = "us-west1"
}
