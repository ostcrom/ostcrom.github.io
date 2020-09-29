FROM python:3.8
WORKDIR /code
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY theme/ .
COPY content/ .
COPY *.py ./
COPY .os_secrets .
COPY .api_secrets .
CMD ["python", "deploy.py"]
