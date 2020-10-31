FROM python:3.8
RUN apk --no-cache add curl grep
WORKDIR /code
RUN git clone https://github.com/ostcrom/danielsteinke.com
WORKDIR danielsteinke.com
VOLUME output
RUN pip install -r requirements.txt
ENTRYPOINT ["python", "deploy.py"]
