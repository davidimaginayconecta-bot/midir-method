SHELL := /bin/bash

.ONESHELL:

.PHONY: env demo clean

env:
	@echo ">> Creando entorno conda 'midir-method'..."
	conda env create -f env.yml || echo "Entorno ya existe. Use 'conda env update -f env.yml' si desea actualizar."
	@echo ">> Para activar: conda activate midir-method"

demo:
	@echo ">> Ejecutando notebooks/N00_demo_lite.ipynb (nbconvert)..."
	python -m jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=600 --inplace notebooks/N00_demo_lite.ipynb
	@echo ">> Demo ejecutada. Revise notebooks/N00_demo_lite.ipynb (celdas ejecutadas)."

clean:
	@echo ">> Limpiando artefactos temporales..."
	find . -name "__pycache__" -type d -prune -exec rm -rf {} +
	find . -name ".ipynb_checkpoints" -type d -prune -exec rm -rf {} +
	find . -name "*.pyc" -delete
	find . -name "*.pyo" -delete
	find . -name "*~" -delete
	@echo ">> Limpieza completada."
