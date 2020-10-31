# danielsteinke.com
 GitHub repo for my static home page.

 Updates to my home page are published to the web by running publish.sh. publish.sh is bash script that uses recursive Makefile commands to maniupulate a Docker image/container to generate a static HTML page, deploy it to object storage and flush cdn. Also performs a rudimentary check that upload was successful by checking that index page has been updated with the git commit hash inside an HTML comment.
