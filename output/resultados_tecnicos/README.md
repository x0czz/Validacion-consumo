# Salidas técnicas completas

Salidas de R (`lavaan` 0.6.17, `semTools` 0.5.6, `psych` 2.4.1) de los modelos del artículo
"Medición de prácticas de consumo socioambientales en Chile". Se generan con
`processing/salidas_tecnicas.R`.

| Archivo | Contenido |
|---|---|
| `01` a `03` | Análisis factorial exploratorio (mitad exploratoria): Bartlett y KMO, análisis paralelo y MAP, solución final. |
| `10` a `17` | Análisis factoriales confirmatorios (mitad de prueba y muestra completa), alternativa de un factor, prueba de diferencia de χ², modelo conjunto y ESEM. |
| `21` a `26` | Invarianza por sexo, edad y NSE de cada escala: ajuste por nivel, diferencias de χ², modelo final completo e índices de modificación. |
| `99` | Versiones del software. |
| `salidas_tecnicas_completas.txt` | Todas las salidas en un solo archivo. |

**Cómo leer los índices de ajuste.** Las salidas de `lavaan` muestran, para cada índice, una
columna *Standard*, una *Scaled* y filas *Robust*. El artículo y el anexo informan los
valores *Scaled* y, para las escalas finales, también los *Robust* (Savalei, 2021), que son
menos favorables para la escala de consumo sustentable y político.

**Advertencia.** La estructura final se seleccionó y evaluó con los mismos datos (ver la
Tabla S16 del material suplementario). Estas salidas documentan los modelos estimados, no
una validación independiente.
