# danielsteinke.com
 GitHub repo for my static home page.

 Updates to my home page are published to the web by running publish.py. That script commits the changes to Github and then runs a Docker image which clones and publishes the updated site to the web. publish.py verifies the new commit hash is present as an HTML comment to verify changes have been published successfull.
