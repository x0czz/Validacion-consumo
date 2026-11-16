# Genera anexo_metodologico_medicion.qmd a partir de paper_medicion.qmd: conserva el
# bloque de configuración, el análisis de datos y los resultados, y renumera las
# tablas y la figura del artículo como A1, A2... Uso: python3 processing/generar_anexo.py
import re, sys
# DESCONTINUADO (noviembre 2026): desde que paper_medicion.qmd resume los procedimientos
# avanzados, anexo_metodologico_medicion.qmd se mantiene como archivo propio y se edita
# directamente. Ejecutar este script lo sobrescribiría con la versión resumida del artículo.
if '--forzar' not in sys.argv:
    sys.exit('generar_anexo.py está descontinuado: edite anexo_metodologico_medicion.qmd directamente '
             '(use --forzar solo si quiere regenerarlo desde el artículo).')
REPO = 'https://github.com/x0czz/Validacion-consumo'
s = open('paper_medicion.qmd').read()
lines = s.split('\n')
yend = [i for i, l in enumerate(lines) if l == '---'][1]
yaml = [l for l in lines[:yend + 1] if not l.startswith(('subtitle:', 'running-title:', '#   ', '# Manuscrito', '# Datos de autor'))]
yaml = [('title: "Anexo metodológico"\nsubtitle: "Medición de prácticas de consumo socioambientales en Chile: evidencia psicométrica de dos escalas breves"'
         if l.startswith('title:') else l) for l in yaml]
body = '\n'.join(lines[yend + 1:])
i = body.index('```{r}'); j = body.index('```\n', body.index('\n', i) + 1) + 4
setup = body[i:j]
k = body.index('## Análisis de datos'); m = body.index('# Discusión')
tecnico = body[k:m].replace('## Análisis de datos', '# Análisis de datos', 1).replace('\n# Resultados\n', '\n# Resultados detallados\n', 1)
intro = ('Este anexo describe en detalle los procedimientos estadísticos y los resultados técnicos del estudio. '
         'El artículo principal resume estos resultados en un lenguaje no técnico. El material suplementario (Tablas S1 a S16 y Figura S1) '
         'acompaña a este anexo; la Tabla S16 registra qué decisiones se especificaron antes de estimar los modelos en la mitad de prueba y cuáles después. '
         'La estructura final se seleccionó y evaluó con los mismos datos, por lo que los resultados que siguen deben leerse como evidencia preliminar. '
         'La descripción de la muestra, el instrumento y el procedimiento de recolección se presenta en el artículo principal. '
         'Todos los documentos, el código y las salidas completas están en ' + REPO + '.\n\n')
cierre = ('\n# Salidas técnicas completas\n\n'
          'Las salidas completas de R para los modelos factoriales y de invarianza están en la carpeta `output/resultados_tecnicos/` del repositorio, '
          'en un archivo por modelo y en un archivo único (`salidas_tecnicas_completas.txt`):\n\n'
          '- Análisis factorial exploratorio: pruebas de Bartlett y KMO, análisis paralelo y MAP, y la solución final de cinco factores (mitad exploratoria).\n'
          '- Análisis factoriales confirmatorios de cada escala en la mitad de prueba y en la muestra completa, la alternativa de un factor, la prueba de diferencia de χ², '
          'el modelo conjunto y el ESEM: estimaciones no estandarizadas y estandarizadas, errores estándar, umbrales, R², índices de ajuste, correlaciones residuales y confiabilidad.\n'
          '- Invarianza por sexo, edad y NSE para cada escala: índices de ajuste de cada nivel, pruebas de diferencia de χ², estimaciones completas del modelo final e índices de modificación de los interceptos.\n\n'
          'Las salidas de `lavaan` muestran dos versiones de los índices de ajuste: la columna *Scaled* corresponde a los valores informados en este anexo, '
          'y las filas *Robust* a las versiones robustas de @savalei_improving_2021, que se comentan en los resultados. '
          'El script `processing/verificacion_reproducibilidad.R` reestima desde los datos las pruebas de Bartlett y la secuencia de invarianza y las compara con las cifras publicadas.\n')
out = '\n'.join(yaml) + '\n\n' + setup + '\n' + intro + tecnico + cierre + '\n# Referencias\n\n::: {#refs}\n:::\n'
out = re.sub(r'Tabla (\d)\b', r'Tabla A\1', out).replace('Figura 1', 'Figura A1')
open('anexo_metodologico_medicion.qmd', 'w').write(out)
