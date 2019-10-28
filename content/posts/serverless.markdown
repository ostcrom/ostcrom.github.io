title: Notes on Creating a "Serverless" Static Web Page with Automated Deployment  
slug: projects/serverless
category: Projects
status: draft


This article is meant to serve as a broad overview for **Why** and **How** modern webpages have moved away from dynamically generated web pages, which were the cornerstone of the "Web 2.0" era. Deployments are trending back towards static web pages, even on websites that contain dynamic content. This method of serving web content relies on modern cloud infrastructure services likes content delivery networks, object storage and edge computing to scale for capacity in an incredibly cost efficient and effortless manner.

####There are three major pieces which are needed to deploy a "Serverless" web page:
1. A way to create and update the web site.
2. A method of deploying said website.
3. A platform or service provider to host the web site on.

Astute readers will already recognize there is no such thing as a "serverless" website. This term refers more to the concept of being able to easily deploy a web application on third party "Backend as a Service" (BaaS) platforms.  This is a break from monolithic CMS platforms of yesteryear which tried to provide all the functionality of web publishing in a single software package and also necessitated a dedicated web server with a runtime interpreter and a database. The exact form of that web server has evolved over time, into increasingly standardized and portable formats (first scriptable languages, then virtual machines, and recently software containers). Despite these advances however the HTTP server/interpreter combo has been pretty consistent in various configurations.

In serverless deployments static content is typically served from a content delivery network, while dynamic content/calls are handled by "serverless functions." These serverless functions are typically scripts with very narrow functionality, that are called when an event is triggered, such as a request to a particular web path or end point. Overall this means that web services are comprised of dead simple static content serving coupled with a gang of "micro" services. Generating a static website means you don't have to call a database to load content into your template, and dynamic elements are rendered on the client side rather than the server side. This description represents what I consider to be a "completely" serverless deployment, however it is easy to imagine a mixture of pieces from either paradigm; as is always the case with web deployment. 🧐

For alternative explanations of Serverless architecture check out these articles:
- [Medium.com - What is Serverless Architecture? What are its criticisms and drawbacks?](https://medium.com/@MarutiTech/what-is-serverless-architecture-what-are-its-criticisms-and-drawbacks-928659f9899a)

## Creating and Uploading the Site
In order to deploy a static site we first of course need a static site. If deploying a single page site with no bells and whistles it is conceivable you could do this without any sort of content management or website framework. However, a website of any greater complexity or one managed by a team  
