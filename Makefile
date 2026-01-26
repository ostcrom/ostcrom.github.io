PY ?= python3
PELICAN ?= pelican
PELICANOPTS =

REGISTRY_HOST ?= danielsteinke.com
VERSION ?= 1.0

REPO_URL ?= https://github.com/ostcrom/ostcrom.github.io
MAIN_BRANCH ?= main
PUBLISH_BRANCH ?= publish

BASEDIR := $(CURDIR)
CURRENT_UID := $(shell id -u)
CURRENT_UID_OPT := --user $(CURRENT_UID)

INPUTDIRNAME := content
INPUTDIR := $(BASEDIR)/$(INPUTDIRNAME)

OUTPUTDIRNAME := docs
OUTPUTDIR := $(BASEDIR)/$(OUTPUTDIRNAME)

CONFFILE := $(BASEDIR)/pelicanconf.py

DEBUG ?= 0
ifeq ($(DEBUG),1)
	PELICANOPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE),1)
	PELICANOPTS += --relative-urls
endif

.PHONY: help generate-html clean serve docker-init docker-html docker-serve

help:
	@echo "Makefile for a Pelican website"
	@echo ""
	@echo "Usage:"
	@echo "  make generate-html   Render content to HTML"
	@echo "  make serve           Serve generated site locally"
	@echo "  make clean           Remove generated output"
	@echo "  make docker-init  REGISTRY_HOST=hostname	Build Docker container image"
	@echo "  make docker-push REGISTRY_HOST=hostname	Push Docker container image to registry."
	@echo "  make docker-html     Generate HTML inside Docker container"
	@echo "  make docker-serve    Serve site inside Docker container"


init:
	git pull $(REPO_URL)

generate-html:
	rm -rf $(OUTPUTDIR)/*
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)
	chmod o+rwx -R $(OUTPUTDIR)/*

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)

serve:
	$(PELICAN) -lr $(INPUTDIR) -o $(OUTPUTDIR) -p 8080 -b 0.0.0.0

docker-init:
	docker build --no-cache -t $(REGISTRY_HOST)/dscom-build:latest \
		-t $(REGISTRY_HOST)/dscom-build:$(VERSION) \
		./

docker-push:
	docker push $(REGISTRY_HOST)/dscom-build:latest
	docker push $(REGISTRY_HOST)/dscom-build:$(VERSION)

docker-html:
	docker run \
		$(CURRENT_UID_OPT) \
		-v $(BASEDIR):/code/danielsteinke.com \
		danielsteinke/dscom-build \
		make generate-html

docker-serve:
	docker run -p 8080:8080 \
		$(CURRENT_UID_OPT) \
		-v $(OUTPUTDIR):/code/danielsteinke.com/$(OUTPUTDIRNAME) \
		danielsteinke/dscom-build \
		pelican -lr content -o $(OUTPUTDIRNAME) -p 8080 -b 0.0.0.0
