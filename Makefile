# By default, show available commands (by finding '##' comments)
.DEFAULT: commands

## commands: show available commands
.PHONY: commands
commands:
	@grep -h -E '^##' ${MAKEFILE_LIST} \
	| sed -e 's/## //g' \
	| column -t -s ':'

## datasets: make all datasets
.PHONY: datasets
datasets: data/lab.db data/designs/.touch data/readings/.touch

data/lab.db: bin/make_db.py data/assay_data.json data/sample_data.csv data/genome_data.json
	@mkdir -p data
	python $< \
	--dbfile $@ \
	--assays data/assay_data.json \
	--samples data/sample_data.csv \
	--sites params/site_params.csv \
	--surveys params/survey_params.csv

## plates: generate plate files
.PHONY: plates
plates: data/designs/.touch data/readings/.touch

data/designs/.touch data/readings/.touch: bin/make_plates.py data/assay_data.json
	rm -rf data/designs data/readings
	@mkdir -p data/designs data/readings
	python $< \
	--assays data/assay_data.json \
	--designs data/designs \
	--params params/assay_params.json \
	--readings data/readings
	touch data/designs/.touch data/readings/.touch

## assays: generate assay files
data/assay_data.json: bin/make_assays.py params/assay_params.json data/genome_data.json data/sample_data.csv
	@mkdir -p data
	python $< \
	--genomes data/genome_data.json \
	--outfile $@ \
	--params params/assay_params.json \
	--samples data/sample_data.csv

## sample_data.csv: sampled snails from survey sites
data/sample_data.csv: bin/make_samples.py data/genome_data.json params/sample_params.json params/site_params.csv params/survey_params.csv
	@mkdir -p data
	python $< \
	--genomes data/genome_data.json \
	--outfile $@ \
	--params params/sample_params.json \
	--sites params/site_params.csv \
	--surveys params/survey_params.csv

## genome_data.json: synthesized genomes
data/genome_data.json: bin/make_genomes.py params/genome_params.json
	@mkdir -p data
	python $< \
	--outfile $@ \
	--params params/genome_params.json

## cleandata: remove all datasets
clean:
	@rm -rf data
	@find . -name '*~' -exec rm {} \;
	@find . -type d -name __pycache__ | xargs rm -r
	@find . -type d -name .pytest_cache | xargs rm -r
