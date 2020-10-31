#!/bin/bash
read -p "Commit message: " COMMSG
git add . &&\
	git add -u && \
	git commit -m "$COMMSG" && \
	git push origin master

#Only rebuild base if req's have changed:
if git diff --exit-code ./requirements.txt; then;
	make docker-base
fi;

make docker-build
make docker-html
make docker-publish

COMMITHASH=$(git rev-parse HEAD)

##Sleep for a bit to allow cache to clear...

sleep 30
##Check if our current commit hash is online
if curl -s https://danielsteinke.com/index.html\?$RANDOM | grep $COMMITHASH; then
	echo Publish successfull!
else
	echo Something went wrong, new commit hash not present.
fi;
