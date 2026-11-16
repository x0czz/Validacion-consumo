# Validación de escalas de prácticas de consumo socioambientales en Chile

Repositorio de análisis de la **Encuesta Sociedad de Consumo 2023** (proyectos Fondecyt N.º 11200893 y N.º 1212677). Contiene el código, resultados y el material complementario de la publicación.

## Publicación: escalas de prácticas de consumo socioambientales

**Marambio-Tapia, A., & Outerbridge Ortega, N. (2026).** *Medición de prácticas de consumo socioambientales en Chile: evidencia psicométrica preliminar de dos escalas breves.* Preprint, SocArXiv. [Enlace por agregar tras la publicación en SocArXiv]

| Documento | Contenido |
|---|---|
| [Preprint (PDF)](https://x0czz.github.io/Validacion-consumo/preprints/Marambio_Outerbridge_2026_medicion_preprint.pdf) | Artículo completo. |
| [Anexo metodológico (PDF)](https://x0czz.github.io/Validacion-consumo/anexo_metodologico_medicion.pdf) · [Word](https://x0czz.github.io/Validacion-consumo/anexos/anexo_metodologico_medicion.docx) | Procedimientos estadísticos, criterios de decisión y resultados técnicos completos: índices de ajuste robustos, modelos bifactor, determinación de los puntajes factoriales, funcionamiento diferencial por ítem y análisis de sensibilidad (Tablas A1 a A4 y Figura A1). |
| [Material suplementario (PDF)](https://x0czz.github.io/Validacion-consumo/suplemento_medicion.pdf) · [Word](https://x0czz.github.io/Validacion-consumo/anexos/material_suplementario_medicion.docx) | Tablas S1 a S17 y Figura S1, citadas en el artículo: descriptivos de los ítems, análisis exploratorio y depuración, parámetros, invarianza, funcionamiento diferencial, ESEM, análisis de sensibilidad (incluida la comparación AFC–ESEM con covariables, Tabla S17) y registro de decisiones del análisis (Tabla S16). |
| [Esquema de las escalas](https://x0czz.github.io/Validacion-consumo/anexos/esquema_escalas.png) | Escalas finales y modelos de medida (Figura 1 del artículo). |

La carpeta [`anexos/`](anexos/) reúne copias del anexo, el material suplementario y el esquema, en PDF y Word.

## Datos y reproducibilidad

Los microdatos de la Encuesta Sociedad de Consumo 2023 pertenecen a los proyectos Fondecyt N.º 11200893 y N.º 1212677 y **no están disponibles públicamente**. Este repositorio contiene:

- `processing/`: código de análisis en R.
- `output/tables/`: resultados agregados de todos los análisis.
- `output/reproducibilidad/`: matrices de correlaciones policóricas y umbrales de los 17 ítems, en la muestra completa y por grupo, para reproducir los modelos sin los microdatos.
- [`REPRODUCIR.md`](REPRODUCIR.md): instrucciones para volver a correr todos los análisis (requiere los microdatos) y generar los PDF.

## Material de trabajo anterior

- [Borrador CFA/EFA](https://x0czz.github.io/Validacion-consumo/)
- [Presentación clases latentes](https://x0czz.github.io/Validacion-consumo/propuesta_presentacion.html)

## Cómo citar

Si usa las escalas o el material de este repositorio, cite el preprint. Licencia de los documentos: CC BY 4.0.

## Estructura del repositorio

<!-- WORKING_TREE_START -->
```text
Validacion-consumo/
 |- .gitignore
 |- .quarto/
 |  |- typst/
 |  |  |- packages/
 |  |  |  |- preview/
 |  |- vdoc/
 |  |  |- .vdoc.3ad1c188-62c0-4d6b-9127-6c559baf28fc.r
 |  |  |- .vdoc.563782c6-b7cc-4d99-ab86-2beca86cc5a5.r
 |- .vscode/
 |  |- settings.json
 |- README.md
 |- REPRODUCIR.md
 |- Redaccion
 |- Untitled-1.qmd
 |- anexo_metodologico_medicion.pdf
 |- anexo_metodologico_medicion.qmd
 |- anexos/
 |  |- README.md
 |  |- anexo_metodologico_medicion.docx
 |  |- anexo_metodologico_medicion.pdf
 |  |- esquema_escalas.pdf
 |  |- esquema_escalas.png
 |  |- material_suplementario_medicion.docx
 |  |- material_suplementario_medicion.pdf
 |- documento_clases_latentes.html
 |- documento_clases_latentes.qmd
 |- documento_invarianza.html
 |- documento_invarianza.qmd
 |- documento_metodologico.html
 |- documento_metodologico.qmd
 |- ejecutar_analisis.R
 |- index.docx
 |- index.html
 |- index.pdf
 |- index.qmd
 |- input/
 |  |- bib/
 |  |  |- Akatu.bib
 |  |  |- apa.csl
 |  |  |- metodologia.bib
 |  |  |- preprints.bib
 |  |- images/
 |  |- literatura/
 |  |  |- Hancock_Mueller_2010_Reviewers_Guide.pdf
 |  |- original-code/
 |  |- templates/
 |  |  |- psicothema.docx
 |- libs/
 |  |- ocs.scss
 |- output/
 |  |- figures/
 |  |  |- esquema_escalas.pdf
 |  |  |- esquema_escalas.png
 |  |- graphs/
 |  |  |- analisis_paralelo_horn_baterias_075.png
 |  |  |- heatmap_indicadores_lca.png
 |  |  |- perfil_lca_46items_1_clases.png
 |  |  |- perfil_lca_46items_2_clases.png
 |  |  |- perfil_lca_46items_2_clases_final.png
 |  |  |- perfil_lca_46items_3_clases.png
 |  |  |- perfil_lca_46items_3_clases_final.png
 |  |  |- perfil_lca_46items_4_clases.png
 |  |  |- perfil_lca_46items_4_clases_final.png
 |  |  |- perfil_lca_46items_5_clases.png
 |  |  |- perfil_lca_46items_6_clases.png
 |  |  |- perfil_lca_46items_7_clases.png
 |  |  |- perfil_lca_46items_8_clases.png
 |  |  |- perfiles_clases.png
 |  |  |- perfiles_clases_46items_5clases.png
 |  |  |- perfiles_clases_depurado.png
 |  |  |- perfiles_clases_factores.png
 |  |  |- scree_lca_46items.png
 |  |  |- scree_lca_representativo.png
 |  |- modelos_lca_13items.rds
 |  |- modelos_lca_O1-O4.rds
 |  |- modelos_lca_O2_1-O2_8-O2_12-O3_3-O3_4-O4_3-O4_1.rds
 |  |- reproducibilidad/
 |  |  |- policoricas_Edad_1834.csv
 |  |  |- policoricas_Edad_3554.csv
 |  |  |- policoricas_Edad_55omas.csv
 |  |  |- policoricas_NSE_ABC1.csv
 |  |  |- policoricas_NSE_C2C3.csv
 |  |  |- policoricas_NSE_DE.csv
 |  |  |- policoricas_Sexo_Hombre.csv
 |  |  |- policoricas_Sexo_Mujer.csv
 |  |  |- policoricas_muestra_completa.csv
 |  |  |- umbrales_Edad_1834.csv
 |  |  |- umbrales_Edad_3554.csv
 |  |  |- umbrales_Edad_55omas.csv
 |  |  |- umbrales_NSE_ABC1.csv
 |  |  |- umbrales_NSE_C2C3.csv
 |  |  |- umbrales_NSE_DE.csv
 |  |  |- umbrales_Sexo_Hombre.csv
 |  |  |- umbrales_Sexo_Mujer.csv
 |  |  |- umbrales_muestra_completa.csv
 |  |- resultados_tecnicos/
 |  |  |- 01_afe_bartlett_kmo.txt
 |  |  |- 02_afe_numero_factores.txt
 |  |  |- 03_afe_solucion_final.txt
 |  |  |- 10_afc_consumo_sustentable_politico_mitad_prueba.txt
 |  |  |- 11_afc_consumo_sustentable_politico_muestra_completa.txt
 |  |  |- 12_afc_consumo_un_factor_mitad_prueba.txt
 |  |  |- 13_afc_practicas_domesticas_mitad_prueba.txt
 |  |  |- 14_afc_practicas_domesticas_muestra_completa.txt
 |  |  |- 15_afc_modelo_conjunto_mitad_prueba.txt
 |  |  |- 16_afc_comparacion_uno_vs_dos_factores.txt
 |  |  |- 17_esem_mitad_prueba.txt
 |  |  |- 21_invarianza_pub_sexo.txt
 |  |  |- 22_invarianza_pub_edad.txt
 |  |  |- 23_invarianza_pub_nse.txt
 |  |  |- 24_invarianza_dom_sexo.txt
 |  |  |- 25_invarianza_dom_edad.txt
 |  |  |- 26_invarianza_dom_nse.txt
 |  |  |- 99_versiones.txt
 |  |  |- README.md
 |  |  |- salidas_tecnicas_completas.txt
 |  |- tables/
 |  |  |- afc_ajuste_modelos.csv
 |  |  |- afc_cargas_m4.csv
 |  |  |- afc_confiabilidad_m4.csv
 |  |  |- afc_conjunto_ajuste.csv
 |  |  |- afc_conjunto_correlaciones.csv
 |  |  |- afc_conjunto_residuos.csv
 |  |  |- afc_reducidos_ajuste.csv
 |  |  |- afc_reducidos_cargas.csv
 |  |  |- afc_reducidos_confiabilidad.csv
 |  |  |- afc_reducidos_estabilidad.csv
 |  |  |- afe_cargas.csv
 |  |  |- afe_comparacion_soluciones.csv
 |  |  |- afe_items_eliminados.csv
 |  |  |- afe_numero_factores.csv
 |  |  |- cluster_jerarquico_stats_k.csv
 |  |  |- colapso_10_resumen.csv
 |  |  |- descriptivos.html
 |  |  |- descriptivos.tex
 |  |  |- esquema_cargas.csv
 |  |  |- esquema_correlaciones.csv
 |  |  |- indices_ajuste_lca_46items.csv
 |  |  |- indices_ajuste_lca_representativo.csv
 |  |  |- indices_robustos.csv
 |  |  |- informe_bifactor_cargas.csv
 |  |  |- informe_breve_final.csv
 |  |  |- informe_breve_registro.csv
 |  |  |- informe_calidad.csv
 |  |  |- informe_cargas_sin_colapsar.csv
 |  |  |- informe_celdas.csv
 |  |  |- informe_celdas_minimas.csv
 |  |  |- informe_determinacion.csv
 |  |  |- informe_dif_interceptos.csv
 |  |  |- informe_dif_medias.csv
 |  |  |- informe_edad_anclas.csv
 |  |  |- informe_esem_ajuste.csv
 |  |  |- informe_esem_cargas.csv
 |  |  |- informe_esem_cor.csv
 |  |  |- informe_htmt.csv
 |  |  |- informe_m9_distribucion.csv
 |  |  |- informe_medias_holm.csv
 |  |  |- informe_sensibilidad.csv
 |  |  |- informe_validez_economica.csv
 |  |  |- invarianza_grupos.csv
 |  |  |- invarianza_interceptos_libres.csv
 |  |  |- invarianza_medias_latentes.csv
 |  |  |- invarianza_parcial_edad.csv
 |  |  |- invarianza_secuencia.csv
 |  |  |- lca_3p_coeficientes.csv
 |  |  |- lca_3p_error_clasificacion.csv
 |  |  |- lca_3p_probabilidades.csv
 |  |  |- lca_3p_vs_ingenuo.csv
 |  |  |- lca_3p_wald.csv
 |  |  |- lca_actitudes_clase.csv
 |  |  |- lca_asociacion_grupos.csv
 |  |  |- lca_bvr.csv
 |  |  |- lca_clasificacion.csv
 |  |  |- lca_comparacion_k.csv
 |  |  |- lca_concordancia.csv
 |  |  |- lca_distribucion_grupos.csv
 |  |  |- lca_enumeracion.csv
 |  |  |- lca_perfiles_dimensiones.csv
 |  |  |- lca_perfiles_items.csv
 |  |  |- lca_perfiles_k.csv
 |  |  |- lca_transiciones_k.csv
 |  |  |- lib/
 |  |  |  |- bootstrap-3.3.5/
 |  |  |  |- jquery-3.6.0/
 |  |  |  |- kePrint-0.0.1/
 |  |  |  |- lightable-0.0.1/
 |  |  |- pruebas_previas_conjuntos.csv
 |  |  |- pruebas_previas_msa_items.csv
 |  |  |- revision_afc_ajuste.csv
 |  |  |- revision_afc_conjunto_cor.csv
 |  |  |- revision_afc_conjunto_residuos.csv
 |  |  |- revision_afc_cor_factores.csv
 |  |  |- revision_afc_dif_chi.csv
 |  |  |- revision_afc_parametros.csv
 |  |  |- revision_afe_coeficientes.csv
 |  |  |- revision_afe_phi.csv
 |  |  |- revision_afe_varianza.csv
 |  |  |- revision_descriptivos_items.csv
 |  |  |- revision_lca_condicionales.csv
 |  |  |- revision_lca_diagnostico.csv
 |  |  |- revision_lca_dicotomico_ari.csv
 |  |  |- revision_lca_dicotomico_enumeracion.csv
 |  |  |- revision_lca_dicotomico_perfiles.csv
 |  |  |- revision_lca_inicios.csv
 |  |  |- revision_lca_limite.csv
 |  |  |- revision_lca_mapa_categorias.csv
 |  |  |- revision_lca_prob_alto.csv
 |  |  |- revision_lca_validez_externa.csv
 |  |  |- revision_lca_validez_wald.csv
 |  |  |- revision_lca_versiones.txt
 |  |  |- revision_validez_externa.csv
 |  |  |- revision_versiones.txt
 |  |  |- sensibilidad_esem_covariables.csv
 |  |  |- sensibilidad_esem_factores.csv
 |  |  |- tabla_cfa_final.html
 |  |  |- tabla_cfa_inicial.html
 |  |  |- tabla_cfa_v2.html
 |  |  |- tabla_efa.html
 |  |  |- tabla_efa_psych.html
 |  |  |- verificacion_bartlett.csv
 |  |  |- verificacion_invarianza.csv
 |  |  |- verificacion_medias.csv
 |  |  |- verificacion_versiones.txt
 |  |- tables_publicado/
 |  |  |- afc_ajuste_modelos.csv
 |  |  |- afc_cargas_m4.csv
 |  |  |- afc_confiabilidad_m4.csv
 |  |  |- afc_conjunto_ajuste.csv
 |  |  |- afc_conjunto_correlaciones.csv
 |  |  |- afc_conjunto_residuos.csv
 |  |  |- afc_reducidos_ajuste.csv
 |  |  |- afc_reducidos_cargas.csv
 |  |  |- afc_reducidos_confiabilidad.csv
 |  |  |- afc_reducidos_estabilidad.csv
 |  |  |- afe_cargas.csv
 |  |  |- afe_comparacion_soluciones.csv
 |  |  |- afe_items_eliminados.csv
 |  |  |- afe_numero_factores.csv
 |  |  |- cluster_jerarquico_stats_k.csv
 |  |  |- colapso_10_resumen.csv
 |  |  |- descriptivos.html
 |  |  |- descriptivos.tex
 |  |  |- esquema_cargas.csv
 |  |  |- esquema_correlaciones.csv
 |  |  |- indices_ajuste_lca_46items.csv
 |  |  |- indices_ajuste_lca_representativo.csv
 |  |  |- indices_robustos.csv
 |  |  |- informe_bifactor_cargas.csv
 |  |  |- informe_breve_final.csv
 |  |  |- informe_breve_registro.csv
 |  |  |- informe_calidad.csv
 |  |  |- informe_cargas_sin_colapsar.csv
 |  |  |- informe_celdas.csv
 |  |  |- informe_celdas_minimas.csv
 |  |  |- informe_determinacion.csv
 |  |  |- informe_dif_interceptos.csv
 |  |  |- informe_dif_medias.csv
 |  |  |- informe_edad_anclas.csv
 |  |  |- informe_esem_ajuste.csv
 |  |  |- informe_esem_cargas.csv
 |  |  |- informe_esem_cor.csv
 |  |  |- informe_htmt.csv
 |  |  |- informe_m9_distribucion.csv
 |  |  |- informe_medias_holm.csv
 |  |  |- informe_sensibilidad.csv
 |  |  |- informe_validez_economica.csv
 |  |  |- invarianza_grupos.csv
 |  |  |- invarianza_interceptos_libres.csv
 |  |  |- invarianza_medias_latentes.csv
 |  |  |- invarianza_parcial_edad.csv
 |  |  |- invarianza_secuencia.csv
 |  |  |- lca_3p_coeficientes.csv
 |  |  |- lca_3p_error_clasificacion.csv
 |  |  |- lca_3p_probabilidades.csv
 |  |  |- lca_3p_vs_ingenuo.csv
 |  |  |- lca_3p_wald.csv
 |  |  |- lca_actitudes_clase.csv
 |  |  |- lca_asociacion_grupos.csv
 |  |  |- lca_bvr.csv
 |  |  |- lca_clasificacion.csv
 |  |  |- lca_comparacion_k.csv
 |  |  |- lca_concordancia.csv
 |  |  |- lca_distribucion_grupos.csv
 |  |  |- lca_enumeracion.csv
 |  |  |- lca_perfiles_dimensiones.csv
 |  |  |- lca_perfiles_items.csv
 |  |  |- lca_perfiles_k.csv
 |  |  |- lca_transiciones_k.csv
 |  |  |- pruebas_previas_conjuntos.csv
 |  |  |- pruebas_previas_msa_items.csv
 |  |  |- revision_afc_ajuste.csv
 |  |  |- revision_afc_conjunto_cor.csv
 |  |  |- revision_afc_conjunto_residuos.csv
 |  |  |- revision_afc_cor_factores.csv
 |  |  |- revision_afc_dif_chi.csv
 |  |  |- revision_afc_parametros.csv
 |  |  |- revision_afe_coeficientes.csv
 |  |  |- revision_afe_phi.csv
 |  |  |- revision_afe_varianza.csv
 |  |  |- revision_descriptivos_items.csv
 |  |  |- revision_lca_condicionales.csv
 |  |  |- revision_lca_diagnostico.csv
 |  |  |- revision_lca_dicotomico_ari.csv
 |  |  |- revision_lca_dicotomico_enumeracion.csv
 |  |  |- revision_lca_dicotomico_perfiles.csv
 |  |  |- revision_lca_inicios.csv
 |  |  |- revision_lca_limite.csv
 |  |  |- revision_lca_mapa_categorias.csv
 |  |  |- revision_lca_prob_alto.csv
 |  |  |- revision_lca_validez_externa.csv
 |  |  |- revision_lca_validez_wald.csv
 |  |  |- revision_lca_versiones.txt
 |  |  |- revision_validez_externa.csv
 |  |  |- revision_versiones.txt
 |  |  |- tabla_cfa_final.html
 |  |  |- tabla_cfa_inicial.html
 |  |  |- tabla_cfa_v2.html
 |  |  |- tabla_efa.html
 |  |  |- tabla_efa_psych.html
 |  |  |- verificacion_bartlett.csv
 |  |  |- verificacion_invarianza.csv
 |  |  |- verificacion_medias.csv
 |  |  |- verificacion_versiones.txt
 |- paper_clases.docx
 |- paper_clases.html
 |- paper_clases.pdf
 |- paper_clases.qmd
 |- paper_clases_files/
 |  |- figure-html/
 |  |  |- figura-perfiles-1.png
 |  |  |- figura-robustez-1.png
 |  |  |- figura-tres-pasos-1.png
 |- paper_medicion.docx
 |- paper_medicion.html
 |- paper_medicion.pdf
 |- paper_medicion.qmd
 |- paper_medicion_files/
 |  |- figure-html/
 |  |  |- fig-medias-1.png
 |  |  |- figura-medias-1.png
 |  |- libs/
 |  |  |- bootstrap/
 |  |  |  |- bootstrap-21c7ad4b31a8d39bca29604a2a3c1441.min.css
 |  |  |  |- bootstrap-icons.css
 |  |  |  |- bootstrap-icons.woff
 |  |  |  |- bootstrap.min.js
 |  |  |- clipboard/
 |  |  |  |- clipboard.min.js
 |  |  |- quarto-html/
 |  |  |  |- anchor.min.js
 |  |  |  |- popper.min.js
 |  |  |  |- quarto-syntax-highlighting-37eea08aefeeee20ff55810ff984fec1.css
 |  |  |  |- quarto.js
 |  |  |  |- tabsets/
 |  |  |  |- tippy.css
 |  |  |  |- tippy.umd.min.js
 |- plantilla.docx
 |- preprint_clases.docx
 |- preprint_clases.pdf
 |- preprint_clases.qmd
 |- preprint_medicion.docx
 |- preprint_medicion.pdf
 |- preprint_medicion.qmd
 |- preprint_medicion_divulgativo.qmd
 |- preprints/
 |  |- Marambio_Outerbridge_2026_clases_preprint.pdf
 |  |- Marambio_Outerbridge_2026_medicion_preprint.pdf
 |- processing/
 |  |- README-prod.md
 |  |- analisis_factorial.html
 |  |- analisis_factorial.qmd
 |  |- clases_latentes.html
 |  |- clases_latentes.qmd
 |  |- esquema_escalas.R
 |  |- exploratory
 |  |- factorial.html
 |  |- factorial.qmd
 |  |- factorial_files/
 |  |  |- figure-html/
 |  |  |  |- unnamed-chunk-10-1.png
 |  |  |  |- unnamed-chunk-11-1.png
 |  |  |  |- unnamed-chunk-15-1.png
 |  |  |- libs/
 |  |  |  |- bootstrap/
 |  |  |  |- clipboard/
 |  |  |  |- quarto-html/
 |  |- figura_esquema.R
 |  |- generar_anexo.py
 |  |- generar_preprint_clases.py
 |  |- generar_preprint_medicion.py
 |  |- indices_robustos.R
 |  |- invarianza.html
 |  |- invarianza.qmd
 |  |- lca.html
 |  |- lca.qmd
 |  |- lca_estimar.R
 |  |- lca_files/
 |  |  |- figure-html/
 |  |  |  |- unnamed-chunk-10-1.png
 |  |  |  |- unnamed-chunk-11-1.png
 |  |  |  |- unnamed-chunk-12-1.png
 |  |  |  |- unnamed-chunk-13-1.png
 |  |  |  |- unnamed-chunk-15-1.png
 |  |  |  |- unnamed-chunk-16-1.png
 |  |  |  |- unnamed-chunk-17-1.png
 |  |  |  |- unnamed-chunk-17-2.png
 |  |  |  |- unnamed-chunk-17-3.png
 |  |  |  |- unnamed-chunk-3-1.png
 |  |  |  |- unnamed-chunk-6-1.png
 |  |  |- libs/
 |  |  |  |- bootstrap/
 |  |  |  |- clipboard/
 |  |  |  |- quarto-html/
 |  |- lca_funciones.R
 |  |- perfiles_4clases.png
 |  |- prep_colapso_10.html
 |  |- prep_colapso_10.qmd
 |  |- prod_analysis.html
 |  |- prod_analysis.qmd
 |  |- prod_prep.html
 |  |- revision_clases.R
 |  |- revision_informe_1.R
 |  |- revision_informe_2.R
 |  |- revision_informe_3.R
 |  |- revision_medicion.R
 |  |- salidas_tecnicas.R
 |  |- sensibilidad_esem_covariables.R
 |  |- verificacion_reproducibilidad.R
 |- propuesta_presentacion.html
 |- propuesta_presentacion.qmd
 |- propuesta_presentacion_files/
 |  |- libs/
 |  |  |- clipboard/
 |  |  |  |- clipboard.min.js
 |  |  |- quarto-html/
 |  |  |  |- light-border.css
 |  |  |  |- popper.min.js
 |  |  |  |- quarto-syntax-highlighting-46f66b053e56abd73bb6e954d61a315b.css
 |  |  |  |- tabby.min.js
 |  |  |  |- tippy.css
 |  |  |  |- tippy.umd.min.js
 |  |  |- revealjs/
 |  |  |  |- dist/
 |  |  |  |- plugin/
 |- render_preprints.R
 |- renv.lock
 |- scripts/
 |  |- update-working-tree.sh
 |- suplemento_clases.docx
 |- suplemento_clases.html
 |- suplemento_clases.pdf
 |- suplemento_clases.qmd
 |- suplemento_medicion.docx
 |- suplemento_medicion.html
 |- suplemento_medicion.pdf
 |- suplemento_medicion.qmd
```
<!-- WORKING_TREE_END -->
