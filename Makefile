shapefiles:
	wget https://data.london.gov.uk/download/statistical-gis-boundary-files-london/9ba8c833-6370-4b11-abdc-314aa020d5e0/statistical-gis-boundaries-london.zip
	unzip statistical-gis-boundaries-london.zip
	mkdir -p shapefiles
	mv statistical-gis-boundaries-london/ESRI/London_Borough_Excluding_MHW* shapefiles/
	rm -rf statistical-gis-boundaries-london statistical-gis-boundaries-london.zip

requirements.txt:
	pipenv lock -r > requirements.txt

.aws-lambda-rie:
	mkdir -p ./.aws-lambda-rie && curl -Lo ./.aws-lambda-rie/aws-lambda-rie \
		https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
		chmod +x ./.aws-lambda-rie/aws-lambda-rie

container: shapefiles requirements.txt
	docker build -t lambda-cycles .

run-local: .aws-lambda-rie
	docker run \
		-v ~/.aws-lambda-rie:/aws-lambda \
		-p 9000:8080 \
		-e API_KEY="${API_KEY}" \
		-e API_SECRET="${API_SECRET}" \
		-e ACCESS_TOKEN="${ACCESS_TOKEN}" \
		-e ACCESS_TOKEN_SECRET="${ACCESS_TOKEN_SECRET}" \
	  	--entrypoint /aws-lambda/aws-lambda-rie lambda-cycles \
	  		/usr/local/bin/python -m awslambdaric app.handler
