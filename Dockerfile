FROM public.ecr.aws/lambda/python:3.8

COPY requirements.txt .
COPY shapefiles/ ./shapefiles/

RUN pip3 install -r requirements.txt

COPY *.py ${LAMBDA_TASK_ROOT}/

CMD ["app.handler"]
