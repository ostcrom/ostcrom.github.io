PY ?= python3
PELICAN ?= pelican
PELICAN_OPTS =

REGISTRY_HOST ?= danielsteinke.com
VERSION ?= 1.0

REPO_URL ?= https://github.com/ostcrom/ostcrom.github.io
MAIN_BRANCH ?= main
PUBLISH_BRANCH ?= publish

BASE_DIR := $(CURDIR)
CURRENT_UID := $(shell id -u)
CURRENT_UID_OPT := --user $(CURRENT_UID)

INPUT_DIR_NAME := content
INPUT_DIR := $(BASE_DIR)/$(INPUT_DIR_NAME)

OUTPUT_DIR_NAME := docs
OUTPUT_DIR := $(BASE_DIR)/$(OUTPUT_DIR_NAME)

CONF_FILE := $(BASE_DIR)/pelicanconf.py

DEBUG ?= 0
ifeq ($(DEBUG),1)
	PELICAN_OPTS += -D
endif

RELATIVE ?= 0
ifeq ($(RELATIVE),1)
	PELICAN_OPTS += --relative-urls
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
	rm -rf $(OUTPUT_DIR)/*
	$(PELICAN) $(INPUT_DIR) -o $(OUTPUT_DIR) -s $(CONF_FILE) $(PELICAN_OPTS)
	chmod o+rwx -R $(OUTPUT_DIR)/*

clean:
	[ ! -d $(OUTPUT_DIR) ] || rm -rf $(OUTPUT_DIR)

serve:
	$(PELICAN) -lr $(INPUT_DIR) -o $(OUTPUT_DIR) -p 8080 -b 0.0.0.0

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
		-v $(BASE_DIR):/code/danielsteinke.com \
		$(REGISTRY_HOST)/dscom-build \
		make generate-html

docker-serve:
	docker run -p 8080:8080 \
		$(CURRENT_UID_OPT) \
		-v $(BASE_DIR):/code/danielsteinke.com \
		$(REGISTRY_HOST)/dscom-build \
		make serve
