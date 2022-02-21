shapefiles:
	wget https://data.london.gov.uk/download/statistical-gis-boundary-files-london/9ba8c833-6370-4b11-abdc-314aa020d5e0/statistical-gis-boundaries-london.zip
	unzip statistical-gis-boundaries-london.zip
	mkdir -p shapefiles
	mv statistical-gis-boundaries-london/ESRI/London_Borough_Excluding_MHW* shapefiles/
	rm -rf statistical-gis-boundaries-london statistical-gis-boundaries-london.zip

requirements.txt:
	pipenv lock -r > requirements.txt

requirements-dev.txt:
	pipenv lock --dev -r > requirements-dev.txt

test-container: shapefiles requirements.txt requirements-dev.txt
	docker build -t test-lambda-cycles --target test-app .

run-test-container:
	docker run -t --entrypoint '' test-lambda-cycles python -m pytest tests/

container: shapefiles requirements.txt requirements-dev.txt
	docker build -t lambda-cycles  --target app .

test: shapefiles
	PYTHONPATH=src pytest tests/

.aws-lambda-rie:
	mkdir -p ./.aws-lambda-rie && curl -Lo ./.aws-lambda-rie/aws-lambda-rie \
		https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
		chmod +x ./.aws-lambda-rie/aws-lambda-rie

run-container: .aws-lambda-rie
	docker run \
		-v ~/.aws-lambda-rie:/aws-lambda \
		-p 9000:8080 \
		-e LAMBDA_TASK_ROOT="/var/task" \
		-e LAMBDA_RUNTIME_DIR="/var/runtime" \
		-e API_KEY="${API_KEY}" \
		-e API_KEY="${API_KEY}" \
		-e API_SECRET="${API_SECRET}" \
		-e ACCESS_TOKEN="${ACCESS_TOKEN}" \
		-e ACCESS_TOKEN_SECRET="${ACCESS_TOKEN_SECRET}" \
	  	--entrypoint /aws-lambda/aws-lambda-rie lambda-cycles \
			/usr/local/bin/python -m awslambdaric app.handler
