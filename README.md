# danielsteinke.com
 GitHub repo for my static home page.

 Updates to my home page are published to the web by running publish.sh. publish.sh is a bash script that uses recursive Makefile commands to maniupulate a Docker image/container to generate a static HTML page, deploy it to object storage and flush cdn. Also performs a rudimentary check that upload was successful by checking that index page has been updated with the git commit hash inside an HTML comment. DS_SECRETS needs to be set in shell and point at an 'env' file with the following keys populated: ds_api_key, ds_api_secret, ds_os_bucket, ds_os_key, ds_os_secret, ds_stack_id.
