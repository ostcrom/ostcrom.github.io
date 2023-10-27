PY?=python3
PELICAN?=pelican
PELICANOPTS=

BASEDIR=$(CURDIR)
CURRENT_UID := $(shell id -u)
CURRENT_UID_OPT=--user $(CURRENT_UID)
INPUTDIRNAME=content
INPUTDIR=$(BASEDIR)/$(INPUTDIRNAME)
OUTPUTDIRNAME=www
OUTPUTDIR=$(BASEDIR)/$(OUTPUTDIRNAME)
CDNAPPLYDIRNAME=cdnreg-tf
CDNAPPLYDIR=$(BASEDIR)/$(CDNAPPLYDIRNAME)
CONFFILE=$(BASEDIR)/pelicanconf.py
SECRETS_ENV=$(DS_SECRETS)


DEBUG ?= 0
ifeq ($(DEBUG), 1)
	PELICANOPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE), 1)
	PELICANOPTS += --relative-urls
endif

help:
	@echo 'Makefile for a pelican Web site                                           '
	@echo '                                                                          '
	@echo 'Usage:                                                                    '
	@echo '   make docker-base                   Generate Docker container requesites'
	@echo '   make docker-html      User docker build image to render content to HTML'
	@echo '   make deploy                      Calls python script to upload website,' 
	@echo '                                   requires secrets to be loaded into ENV.'
	@echo '   make html                           (re)generate the web site          '
	@echo '   make clean                          remove the generated files         '
	@echo '   make regenerate                     regenerate files upon modification '
	@echo '   make serve [PORT=8000]              serve site at http://localhost:8000'
	@echo '   make serve-global [SERVER=0.0.0.0]  serve (as root) to $(SERVER):80    '
	@echo '   make devserver [PORT=8000]          serve and regenerate together      '
	@echo '   make ssh_upload                     upload the web site via SSH        '
	@echo '   make rsync_upload                   upload the web site via rsync+ssh  '
	@echo '                                                                          '
	@echo 'Set the DEBUG variable to 1 to enable debugging, e.g. make DEBUG=1 html   '
	@echo 'Set the RELATIVE variable to 1 to enable relative urls                    '
	@echo '                                                                          '

##Init targets
## These targets need to be run first, they create the docker images used to generate the HTML and deploy the site.

init-base:
	docker build --no-cache -t danielsteinke/dscom-base docker-base/.

init-terraform:
	docker build -t danielsteinke/dscom-terraform docker-terraform/.
	docker run -i -t \
		-v $(BASEDIR):$(BASEDIR) -w $(BASEDIR) \
		danielsteinke/dscom-terraform init

##Main targets
##These three targets are the main targets, to generate the HTML,
##and deploy infrastructure/changes to Azure. 
generate-html:
	docker run -v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		$(CURRENT_UID_OPT) \
		danielsteinke/dscom-base make html
terraform-init:
	docker run -i -t -v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		$(CURRENT_UID_OPT) \
		danielsteinke/dscom-terraform init


terraform-apply:
	docker run -i -t -v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		$(CURRENT_UID_OPT) \
		danielsteinke/dscom-terraform apply -auto-approve

terraform-destroy:
	docker run -i -t -v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		$(CURRENT_UID_OPT) \
		danielsteinke/dscom-terraform destroy
terraform-apply-cdn:
	docker run -i -t -v $(CURDIR)/:$(CURDIR) \
		-w $(CDNAPPLYDIR) $(CURRENT_UID_OPT) \
		danielsteinke/dscom-terraform init \
		--var-file="../terraform.tfvars"
	docker run -i -t -v $(CURDIR)/:$(CURDIR) \
		-w $(CDNAPPLYDIR) $(CURRENT_UID_OPT) \
		danielsteinke/dscom-terraform apply -auto-approve \
		--var-file="../terraform.tfvars"

##These targets launch a test server to view the current output. 
docker-serve:
	docker run -p 8080:8080 \
		$(CURRENT_UID_OPT) \
		-v $(OUTPUTDIR):/code/danielsteinke.com/$(OUTPUTDIRNAME) \
		danielsteinke/dscom-base \
		pelican -lr content \
		-o $(OUTPUTDIRNAME) -p 8080 -b 0.0.0
docker-serve-d:
	docker run -d -p 8080:8080 \
		$(CURRENT_UID_OPT) \
		-v $(OUTPUTDIR):/code/danielsteinke.com/$(OUTPUTDIRNAME) \
		danielsteinke/dscom-base \
		pelican -lr content \
		-o $(OUTPUTDIRNAME) -p 8080 -b 0.0.0

##None of these targets should be called directly under normal operation.
html:
	rm -rf $(OUTPUTDIR)/*
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)
	chmod o+rwx -R $(OUTPUTDIR)/*

dns-sync:
	python dns-sync.py $(GD_API_KEY) $(GD_API_SECRET) $(GD_SHOPPER_ID) $(TARGET_DOMAIN) $(NS_DATA)

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)

serve:
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -p 8080 -b 0.0.0.0


devserver:
ifdef PORT
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS) -p $(PORT)
else
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)
endif

.PHONY: html help clean regenerate serve serve-global devserver publish 
