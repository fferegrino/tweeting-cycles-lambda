ARG FUNCTION_DIR="/var/task"
ARG PYTHON_IMAGE=3.8-slim-buster

# Create a base image
FROM python:${PYTHON_IMAGE} AS build-image

# Capture the outside FUNCTION_DIR argument
ARG FUNCTION_DIR

# Create the function directory inside build-image
RUN mkdir -p ${FUNCTION_DIR}

# Install some build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      binutils \
      g++ \
      gdal-bin \
      libgdal-dev \
      libproj-dev \
      python-gdal \
      python3-gdal

# Copy and install requirements (and install the AWS Lambda RIE)
COPY requirements.txt ./

RUN pip install --compile --target ${FUNCTION_DIR} awslambdaric && \
    pip install --compile --target ${FUNCTION_DIR} -r requirements.txt
