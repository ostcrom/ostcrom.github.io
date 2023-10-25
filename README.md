#danielsteinke.com

This repo allows you to generate the static HTML site for danielsteinke.com using the Pelican framework in Python and deploy it to Azure using Terraform.

## Steps:
1. Fill out terraform.tfvars.example with the appropriate values.
2. Run:
```
sudo ./Setup.sh
make init-base
make init-build
make docker-html
terraform init
terraform apply
```
3. Congrats, you've deployed danielsteinke.com.
