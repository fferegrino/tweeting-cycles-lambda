# Define function directory
ARG FUNCTION_DIR="/var/task"

FROM python:3.8-slim-buster as build-image

ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal

RUN apt-get update && \
    apt-get install -y \
      binutils libproj-dev gdal-bin libgdal-dev python-gdal python3-gdal g++ --no-install-recommends

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}


COPY requirements.txt ./

# Install the runtime interface client
RUN pip install --no-cache-dir --compile \
        --target  ${FUNCTION_DIR} \
        awslambdaric && \
    pip install --no-cache-dir --compile --target ${FUNCTION_DIR} -r requirements.txt

# Multi-stage build: grab a fresh copy of the base image
FROM python:3.8-slim-buster as app

ENV LAMBDA_TASK_ROOT=/var/task
ENV LAMBDA_RUNTIME_DIR=/var/runtime

ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}

# Copy function code
COPY ./*.py ${FUNCTION_DIR}/
COPY ./shapefiles ${FUNCTION_DIR}/shapefiles

# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]
