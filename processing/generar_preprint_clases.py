# Genera preprint_clases.qmd desde paper_clases.qmd (versión Psicothema): quita el
# anonimato, agrega la portada con autores y ORCID, y ajusta las declaraciones.
# Uso, desde la carpeta del proyecto: python processing/generar_preprint_clases.py
import re, sys
FONDECYT = 'los proyectos Fondecyt N.º 11200893 y N.º 1212677'
autores = '''**Alejandro Marambio-Tapia**^1^ (ORCID: https://orcid.org/0000-0002-8598-8817) y **Nicolás Outerbridge Ortega**^2^ (ORCID: https://orcid.org/0009-0009-1943-6182)

^1^ Escuela de Trabajo Social, Universidad de Chile, Santiago, Chile.

^2^ Departamento de Sociología, Universidad de Chile, Santiago, Chile.

**Autor de correspondencia:** Nicolás Outerbridge Ortega, nicolas.outerbridge@ug.uchile.cl

**Preprint** publicado en SocArXiv bajo licencia CC BY 4.0. Esta versión no ha sido revisada por pares.
'''
contrib = ('Alejandro Marambio-Tapia: Conceptualización, Investigación, Metodología, Análisis formal, '
           'Redacción – borrador original. Nicolás Outerbridge Ortega: Curación de datos, Análisis formal, '
           'Visualización, Redacción – borrador original, Redacción – revisión y edición.')
ia = ('# Declaración de uso de inteligencia artificial\n\n'
      'En la preparación de este trabajo se usó Claude (Anthropic; modelo Claude Opus 5.5, 2026) '
      'para pulir la redacción, limpiar y generar código de análisis en R y gestionar las referencias. '
      'Los autores revisaron y verificaron todo el código, los resultados y las referencias, y escribieron '
      'la versión final del texto, de cuyo contenido son responsables.\n\n')
muestra = ('La muestra proviene de un panel en línea no probabilístico [Por confirmar: proveedor del panel]. '
           'La selección no usó cuotas, no se dispone de una tasa de participación y no se ofrecieron incentivos.')
etica = ('Este estudio es un análisis secundario de datos anonimizados: la encuesta se levantó en el marco del proyecto '
         + FONDECYT + ', con objetivos más amplios que los de este artículo. '
         '[Por confirmar: procedimiento de obtención del consentimiento informado.]')

def transformar(src, dst, n_tablas):
    s = open(src).read()
    def rep(old, new, count=1):
        nonlocal s
        assert s.count(old) == count, (src, old[:70], s.count(old))
        s = s.replace(old, new)
    # YAML: quitar subtítulo, título reducido y comentarios de anonimización
    s = re.sub(r'subtitle: ".*"\n', '', s, count=1)
    s = re.sub(r'running-title: ".*"\n', '', s, count=1)
    s = re.sub(r'# Manuscrito anonimizado.*?\n(#.*\n)*', '', s, count=1)
    s = s.replace('  - "input/bib/metodologia.bib"\n', '  - "input/bib/metodologia.bib"\n  - "input/bib/preprints.bib"\n', 1)
    # Portada
    i = s.index('**Título reducido:**'); j = s.index('{{< pagebreak >}}', i)
    s = s[:i] + autores + '\n' + s[j:]
    # Marcas
    s = re.sub(r'Autor 1: Conceptualización.*?revisión y edición\.', contrib, s, count=1)
    rep('El material suplementario (Tablas S1 a S6) y el código de análisis en R están disponibles en',
        'El material suplementario (Tablas S1 a S6) se incluye al final de este documento. Ese material y el código de análisis en R están disponibles en')
    rep('# Referencias', ia + '# Referencias')
    s = s.replace('[referencia anonimizada]', '[@marambio_medicion_2026]')
    assert 'anonimiz' not in s.lower().replace('datos anonimizados', ''), [m for m in re.findall(r'.{40}anonimiz.{20}', s)]
    assert 'Psicothema' not in s.split('---', 2)[2], 'residuos'
    open(dst, 'w').write(s)

# preprint_medicion.qmd es ahora una versión divulgativa escrita aparte (no se genera aquí)
transformar('paper_clases.qmd', 'preprint_clases.qmd', 6)
