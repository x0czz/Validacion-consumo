# Template reporte reproducibilidad

Link al reporte [**AQUÍ**](https://data-soc.github.io/template-repro/)

Este repositorio contiene una plantilla para el reporte de reproducibilidad del Trabajo 1 del curso [Investigación Social Abierta](https://cienciasocialabierta.cl/2026/). La plantilla está diseñada para ser clonada y modificada por cada estudiante, siguiendo el protocolo [IPO](https://lisacoes.com/protocolos/a-ipo-rep/) (IInput-Processing-Output) y utilizando el formato Quarto.

<img src="https://lisacoes.com/protocolos/a-ipo-rep/ipo-hex.png" alt="IPO" width="220" />

## Working tree del proyecto

Este proyecto se organiza de la siguiente manera: 

<!-- WORKING_TREE_START -->
```text
Validacion-consumo/
 |- .quarto/
 |  |- typst/
 |  |  |- packages/
 |  |  |  |- preview/
 |- .vscode/
 |  |- settings.json
 |- README.md
 |- Redaccion
 |- index.docx
 |- index.html
 |- index.pdf
 |- index.qmd
 |- input/
 |  |- bib/
 |  |  |- Akatu.bib
 |  |  |- apa.csl
 |  |- data/
 |  |  |- original/
 |  |  |  |- Encuesta Sociedad de Consumo 2023.sav
 |  |  |- proc/
 |  |  |  |- proc_casen22.rds
 |  |- images/
 |  |- original-code/
 |- libs/
 |  |- ocs.scss
 |- output/
 |  |- graphs/
 |  |- tables/
 |- plantilla.docx
 |- processing/
 |  |- README-prod.md
 |  |- library(dplyr).r
 |  |- prod_analysis.Rmd
 |  |- prod_analysis.html
 |  |- prod_prep.Rmd
 |  |- prod_prep.html
 |- scripts/
 |  |- update-working-tree.sh
```
<!-- WORKING_TREE_END -->

Este working tree incorpora las carpetas y archivos principales relevantes del repo (omite algunas) y se actualiza automáticamente al hacer commit mediante una github action que se encuentra definida en el archivo `.github/workflows/update-working-tree.yml`. El propósito de esta acción es mantener un registro actualizado de la estructura del proyecto, lo que facilita la navegación y organización de los archivos para los estudiantes.


