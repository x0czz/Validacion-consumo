# Genera preprint_medicion.qmd (versión para SocArXiv) desde paper_medicion.qmd (versión
# Psicothema): quita el anonimato, agrega la portada con autores y ORCID, la declaración de
# uso de IA y una sección de anexos con los enlaces al repositorio, donde están el anexo
# metodológico completo y el material suplementario (no se adjuntan al PDF del preprint).
# Uso, desde la carpeta del proyecto: python processing/generar_preprint_medicion.py
# La versión divulgativa anterior quedó en preprint_medicion_divulgativo.qmd.
import re
REPO = 'https://github.com/x0czz/Validacion-consumo'
ARCH = 'https://x0czz.github.io/Validacion-consumo/'
autores = '''**Alejandro Marambio-Tapia**^1^ (ORCID: https://orcid.org/0000-0002-8598-8817) y **Nicolás Outerbridge Ortega**^2^ (ORCID: https://orcid.org/0009-0009-1943-6182)

^1^ Escuela de Trabajo Social, Universidad de Chile, Santiago, Chile.

^2^ Departamento de Sociología, Universidad de Chile, Santiago, Chile.

**Autor de correspondencia:** Nicolás Outerbridge Ortega, nicolas.outerbridge@ug.uchile.cl

**Preprint** publicado en SocArXiv bajo licencia CC BY 4.0. Esta versión no ha sido revisada por pares.
'''
contrib = ('Alejandro Marambio-Tapia: Conceptualización, Investigación, Metodología, Análisis formal, '
           'Redacción – borrador original. Nicolás Outerbridge Ortega: Curación de datos, Análisis formal, '
           'Visualización, Redacción – borrador original, Redacción – revisión y edición.')
anexos = ('# Anexos y material suplementario\n\n'
          'Este artículo se acompaña de dos documentos disponibles en el repositorio del estudio (' + REPO + '):\n\n'
          '- **Anexo metodológico** (' + ARCH + 'anexo_metodologico_medicion.pdf): procedimientos estadísticos y resultados técnicos completos, '
          'incluidos los índices de ajuste robustos, los modelos bifactor, la determinación de los puntajes factoriales, '
          'el funcionamiento diferencial por ítem y los análisis de sensibilidad.\n'
          '- **Material suplementario** (' + ARCH + 'suplemento_medicion.pdf): Tablas S1 a S17 y Figura S1, citadas en el texto.\n\n'
          'El repositorio contiene además el código de análisis en R, las salidas técnicas completas de los modelos '
          '(carpeta `output/resultados_tecnicos/`) y las matrices de correlaciones y umbrales necesarias para reproducir los modelos '
          'sin los microdatos.\n\n')
ia = ('# Declaración de uso de inteligencia artificial\n\n'
      'En la preparación de este trabajo se usó Claude (Anthropic; modelo Claude Opus 5.5, 2026) '
      'para pulir la redacción, limpiar y generar código de análisis en R y gestionar las referencias. '
      'Los autores revisaron y verificaron todo el código, los resultados y las referencias, y escribieron '
      'la versión final del texto, de cuyo contenido son responsables.\n\n')

s = open('paper_medicion.qmd').read()
def rep(old, new):
    global s
    assert s.count(old) == 1, (old[:70], s.count(old))
    s = s.replace(old, new)
s = re.sub(r'running-title: ".*"\n', '', s, count=1)
s = re.sub(r'# Manuscrito anonimizado.*?\n(#.*\n)*', '', s, count=1)
s = s.replace('# doble espacio — Psicothema', '# doble espacio')
i = s.index('**Título reducido:**'); j = s.index('{{< pagebreak >}}', i)
s = s[:i] + autores + '\n' + s[j:]
s = re.sub(r'Autor 1: Conceptualización.*?revisión y edición\.', contrib, s, count=1)
rep('# Referencias', anexos + ia + '# Referencias')
assert 'anonimiz' not in s.lower().replace('datos anonimizados', '')
assert 'Psicothema' not in s.split('---', 2)[2].replace('@munniz_diez_2019', ''), re.findall(r'.{40}Psicothema.{20}', s)
open('preprint_medicion.qmd', 'w').write(s)
print('preprint_medicion.qmd generado')
