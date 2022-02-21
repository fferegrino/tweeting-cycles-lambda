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

container: shapefiles requirements.txt
	docker build -t lambda-cycles .

test: shapefiles
	PYTHONPATH=src pytest tests/
