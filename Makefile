PY?=python3
PELICAN?=pelican
PELICANOPTS=

BASEDIR=$(CURDIR)
CURRENT_UID := $(shell id -u)
CURRENT_UID_OPT=--user $(CURRENT_UID)
INPUTDIRNAME=content
INPUTDIR=$(BASEDIR)/$(INPUTDIRNAME)
OUTPUTDIRNAME=docs
OUTPUTDIR=$(BASEDIR)/$(OUTPUTDIRNAME)
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
	@echo '   make generate-html      User docker build image to render content to HTML'
	@echo '                                                                          '

##Init targets
## These targets need to be run first, they create the docker images used to generate the HTML and deploy the site.

init-base:
	docker build --no-cache -t danielsteinke/dscom-base docker-base/.

##Main targets
##These three targets are the main targets, to generate the HTML,
##and deploy infrastructure/changes to Azure. 
generate-html:
	docker run -v $(CURDIR):$(CURDIR) -w $(CURDIR) \
		$(CURRENT_UID_OPT) \
		danielsteinke/dscom-base make html

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
