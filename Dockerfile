FROM python:3.8
WORKDIR /code
RUN git clone https://github.com/ostcrom/danielsteinke.com
WORKDIR danielsteinke.com
VOLUME output
RUN pip install -r requirements.txt
ENTRYPOINT ["python", "deploy.py"]
