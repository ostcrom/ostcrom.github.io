#!/bin/bash
read -p "Commit message: " COMMSG
git add . &&\
	git add -u && \
	git commit -m "$COMMSG" && \
	git push origin master &&\
	./deploy.sh
