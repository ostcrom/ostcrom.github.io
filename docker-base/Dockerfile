FROM python:3.8
WORKDIR /code
RUN git clone https://github.com/ostcrom/danielsteinke.com
WORKDIR danielsteinke.com
RUN pip install -r requirements.txt
WORKDIR /code/danielsteinke.com
RUN git pull origin
VOLUME output
