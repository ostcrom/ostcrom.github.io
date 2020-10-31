# danielsteinke.com
 GitHub repo for my static home page.

 Updates to my home page are published to the web by running publish.sh. That script commits the changes to Github and then runs a Docker image which clones the repo, builds the static HTML and publishes the updated site to the web. publish.py verifies the new commit hash is present as an HTML comment to verify an update has been published successfully.
