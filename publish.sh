#!/bin/bash

##If no options are specified we do a normal build, otherwise we only run the specified items.
if [[ $# -eq 0 ]]; then
	DO_GIT=1
	DO_BASE=0
	DO_BUILD=1
	DO_HTML=1
	DO_PUBLISH=1
	DO_TEST=1
else	
	DO_GIT=0
	DO_BASE=0
	DO_BUILD=0
	DO_HTML=0
	DO_PUBLISH=0
	DO_TEST=0
	while getopts ":gabhpt" opt; do
		case $opt in
			g) DO_GIT=1
				;;
			a) DO_BASE=1
				;;
			b) DO_BUILD=1
				;;
			h) DO_HTML=1
				;;
			p) DO_PUBLISH=1
				;;
			t) DO_TEST=1
				;;
		esac;	
	done;
fi;

##Commit to git.
if [[ $DO_GIT -eq 1 ]]; then
	git pull origin
	echo "Commiting to git..."
	read -p "Commit message: " COMMSG
	git add . &&\
		git add -u && \
		git commit -m "$COMMSG" && \
		git push origin master
fi;

git diff --exit-code ./requirements.txt

#Only rebuild base if req's have changed:
if [[ $? -eq 1 ]] || [[ $DO_BASE -eq 1 ]]; then
	echo "Building base image..."
	make docker-base
fi;

if [[ $DO_BUILD -eq 1 ]]; then
	echo "Building Pelican build image..."
	make docker-build
fi;

if [[ $DO_HTML -eq 1 ]]; then
	echo "Running Pelican build..."
	make docker-html
fi;

if [[ $DO_PUBLISH -eq 1 ]]; then
	echo "Publishing to web..."
	make docker-publish
fi;

if [[ $DO_TEST -eq 1 ]]; then
	git pull origin
	echo "Checking that commit hash is published in HTML comment..."
	COMMITHASH=$(git rev-parse HEAD)

	##Sleep for a bit to allow cache to clear...

	sleep 5
	##Check if our current commit hash is online
	if curl -s https://danielsteinke.com/index.html\?$RANDOM | grep $COMMITHASH; then
		echo Publish successfull!
	else
		echo Something went wrong, new commit hash not present.
	fi;
fi;
