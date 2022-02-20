shapefiles:
	wget https://data.london.gov.uk/download/statistical-gis-boundary-files-london/9ba8c833-6370-4b11-abdc-314aa020d5e0/statistical-gis-boundaries-london.zip
	unzip statistical-gis-boundaries-london.zip
	mkdir -p shapefiles
	mv statistical-gis-boundaries-london/ESRI/London_Borough_Excluding_MHW* shapefiles/
	rm -rf statistical-gis-boundaries-london statistical-gis-boundaries-london.zip

requirements.txt:
	pipenv lock -r > requirements.txt

container: shapefiles requirements.txt
	docker build -t lambda-cycles .

test: shapefiles
	PYTHONPATH=src pytest tests/
