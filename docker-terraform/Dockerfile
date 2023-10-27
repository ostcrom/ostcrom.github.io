FROM hashicorp/terraform:latest
RUN apk update && apk upgrade && apk add --update alpine-sdk && \
    apk add --no-cache make python3 py3-pip git
WORKDIR /code
ADD ./requirements.txt /code/requirements.txt
RUN pip install -r requirements.txt
