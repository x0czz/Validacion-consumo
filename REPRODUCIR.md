# Cómo reproducir los análisis

## Opción rápida: con su R y sus paquetes actuales

Con la base original en `input/data/original/`, abrir el proyecto y ejecutar:

```r
source("ejecutar_analisis.R")
```

El script instala solo los paquetes que falten, muestra qué versiones está usando y, al
terminar, compara cada cifra con las publicadas en `output/comparacion_versiones.csv`.
Con otras versiones de `lavaan`, `semTools` o `psych` pueden variar algunos decimales.

## Opción exacta: con las mismas versiones del análisis publicado

Los resultados publicados se obtuvieron con **R 4.3.3**, **lavaan 0.6-17**, **semTools 0.5-6**,
**psych 2.4.1** y **poLCA 1.6.0.2**. El archivo `renv.lock` fija la versión exacta de los 130
paquetes usados, de modo que los análisis se pueden repetir con el mismo software.

## 1. Instalar R 4.3.3

Se puede tener junto a otras versiones de R.

- **Windows:** descargar el instalador desde <https://cran.r-project.org/bin/windows/base/old/4.3.3/>.
  En RStudio, elegir la versión en *Tools → Global Options → General → R version*.
- Alternativa para manejar varias versiones: [rig](https://github.com/r-lib/rig) (`rig add 4.3.3`).

## 2. Restaurar los paquetes

Con el proyecto abierto en R 4.3.3:

```r
install.packages("renv")
renv::restore()
```

`renv` instala las versiones del archivo `renv.lock` desde una copia de CRAN fechada el
1 de marzo de 2024 (Posit Package Manager), que ofrece binarios para Windows. Si algún
paquete con código compilado (por ejemplo, `poLCA`) se instalara desde el código fuente,
se necesita [Rtools43](https://cran.r-project.org/bin/windows/Rtools/rtools43/rtools.html).

## 3. Datos

La base original (`input/data/original/Encuesta Sociedad de Consumo 2023.sav`) pertenece a
los proyectos Fondecyt N.º 11200893 y N.º 1212677 y no está en el repositorio. Debe copiarse
en esa ruta antes de ejecutar los análisis.

Sin los microdatos, los modelos factoriales y de invarianza pueden reproducirse con las
matrices de correlaciones policóricas y umbrales de `output/reproducibilidad/`.

## 4. Ejecutar

```r
source("ejecutar_analisis.R")   # todos los análisis, en orden (40 a 60 minutos)
source("render_preprints.R")    # PDF de los preprints con sus anexos
```

`ejecutar_analisis.R` verifica la versión de R y de los paquetes principales antes de empezar.
La división aleatoria de la muestra y los inicios de las clases latentes usan semillas fijas,
por lo que con las mismas versiones los resultados deberían coincidir con los publicados.
