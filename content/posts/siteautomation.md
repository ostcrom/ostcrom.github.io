title: Building a Static Web App with 
summary: Website Publishing Automation with Gitp and Python; deployed on object storage and CDN.
status: draft
category: Projects
slug: projects/website-automation
author: dsteinke

Recently, as a technical exercise, I decided to create an automated deployment pipeline for my website. This approach is definitely over engineered for the amount of content I publish, however I believe this 'simple' design would be a good starting point for any web publication. That is, something like an online news magazine or blog, where whole articles are added regularly, but otherwise the content remains fairly static. Obviously there are tons of ways to go about this, so allow me to explain the defining features of my implementation.
## System Features
- Content is composed easily in Markdown, a mark *up* language that is intuitive enough for nearly any writer to use. Writers can use any number of plaintext text editors to compose well formatted articles.
- Our website is compiled into themed HTML pages using a Python module called Pelican. We need Python to build these HTML pages, but only a bog standard HTTP/S host to actually serve the page to end users.
- Actual hosting of this website is cheap and would scale well if I received a ton of traffic. This is because I use AWS-style Object Storage to store the webpage, and then a CDN to cache and serve the web page to end users. The end user only ever interacts with my CDN, guaranteeing the snappiest of load times. My website is so small that 
- It uses Heroku to automatically build and publish the website, meaning adding an article is a matter of composing in Markdown and pushing the changes to Git. Once content is pushed to the Github repo, Heroku runs my build script and publishes the page. 

Granted, my site does not feature any dynamic content whatsoever, this approach could easily be expanded to incorporate that (think Javascript and microservices.) 

