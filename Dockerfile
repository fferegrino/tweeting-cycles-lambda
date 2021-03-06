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


# Create a test-app image based on build-image
FROM build-image AS test-app

# Capture the outside FUNCTION_DIR argument
ARG FUNCTION_DIR

# Copy and install our dev requirements
COPY requirements-dev.txt ./
RUN pip install -r requirements-dev.txt

# Copy our source files INCLUDING tests
WORKDIR ${FUNCTION_DIR}
COPY ./src/*.py ${FUNCTION_DIR}/
COPY ./shapefiles ${FUNCTION_DIR}/shapefiles
COPY ./tests ${FUNCTION_DIR}/tests


# Start from a fresh Python base image as app
FROM python:${PYTHON_IMAGE} AS app

# Capture the outside FUNCTION_DIR argument
ARG FUNCTION_DIR

# Copy all our Python dependencies from the `build-image`
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# Copy our source files
COPY ./src/*.py ${FUNCTION_DIR}/
COPY ./shapefiles ${FUNCTION_DIR}/shapefiles

# Set the current directory to FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}

# Set the entry point to
ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]

# Tell lambda where to find our code's entrypoint
CMD [ "app.handler" ]
