# danielsteinke.com

This repo allows you to generate the static HTML site for danielsteinke.com using the Pelican framework in Python and deploy it to Azure using Terraform.

## Quickstart:
1. Fill out terraform.tfvars.example with the appropriate values.
2. Run:
```
sudo ./Setup.sh
make init-base
make init-terraform
make generate-html
make terraform-apply
```
3. Congrats, you've deployed danielsteinke.com.

4. To destory:
```
make terraform-destroy
```

5. If there are issues destorying due to the CDN Feature Registration, fix it by running this make target:
```
make terraform-apply-cdn
```
