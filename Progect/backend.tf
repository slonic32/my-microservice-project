terraform {
  backend "s3" {
    bucket       = "terraform-state-bucket-hordiyevskyy77" # Назва S3-бакета
    key          = "lesson-7/terraform.tfstate"            # Шлях до файлу стейту
    region       = "eu-central-1"                          # Регіон AWS
    use_lockfile = true
    encrypt      = true # Шифрування файлу стейту
  }
}