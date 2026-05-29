library(tidyverse)
library(psych)
library(lavaan)
library(semTools)
library(semPlot)
library(haven)
options(scipen = 999)

# -------------------------------------------------------
# 1) Carga y preparación inicial de variables de batería
# -------------------------------------------------------

Encuesta_Sociedad_de_Consumo_2023 <- read_sav("input/data/original/Encuesta Sociedad de Consumo 2023.sav")

baterias <- Encuesta_Sociedad_de_Consumo_2023 %>%
	select(
		starts_with("O1"),
		starts_with("O2"),
		starts_with("O3"),
		starts_with("O4")
	)

baterias <- baterias %>%
	mutate(across(
		starts_with("O4"),
		~ if (grepl("_RECOD$", cur_column())) . else 6 - .
	))

colapsa_extremos <- function(x, min_prop = 0.05) {
	validos <- x[!is.na(x)]
	proporciones <- prop.table(table(validos))
	if (length(proporciones) < 2) return(x)
	niveles <- sort(unique(validos))
	if (as.numeric(proporciones[1]) < min_prop) {
		x[x == niveles[1]] <- niveles[2]
	}
	validos <- x[!is.na(x)]
	proporciones <- prop.table(table(validos))
	niveles <- sort(unique(validos))
	if (as.numeric(tail(proporciones, 1)) < min_prop) {
		x[x == tail(niveles, 1)] <- niveles[length(niveles) - 1]
	}
	x
}

baterias <- baterias %>%
	mutate(across(everything(), colapsa_extremos))

# Eliminar variables terminadas en _RECOD
baterias <- baterias %>%
	select(-ends_with("_RECOD"))


# -------------------------------------------------------
# 2) Limpieza general y codificación ordinal
# -------------------------------------------------------

baterias_limpio <- baterias %>%
	drop_na() %>%
	mutate(across(everything(), ~ as.ordered(as.numeric(.))))

matriz_poly_baterias <- psych::polychoric(baterias_limpio)$rho


# KMO con variables tratadas como continuas (correlacion de Pearson)
baterias_continuas <- baterias_limpio %>%
	mutate(across(everything(), as.numeric))

matriz_cor_continua <- cor(baterias_continuas)
kmo_baterias <- psych::KMO(matriz_cor_continua)
kmo_baterias

# -------------------------------------------------------
# 3) Selección de ítems con MSA >= 0.75 y guardado reproducible
# -------------------------------------------------------

# Subset con variables que tienen MSA >= 0.75
msa_por_item <- kmo_baterias$MSAi
items_msa_075 <- sort(msa_por_item[msa_por_item >= 0.75], decreasing = TRUE)

baterias_msa_075 <- baterias %>%
	select(any_of(names(items_msa_075)))

items_msa_075
baterias_msa_075

# Prueba de esfericidad de Bartlett para subset baterias_msa_075
baterias_msa_075_limpio <- baterias_msa_075 %>%
	drop_na() %>%
	mutate(across(everything(), ~ as.ordered(as.numeric(.))))

archivo_baterias_msa_075_limpio <- file.path("input", "data", "proc", "baterias_msa_075_limpio.rds"); if (!file.exists(archivo_baterias_msa_075_limpio)) saveRDS(baterias_msa_075_limpio, file = archivo_baterias_msa_075_limpio)

variables_msa_075 <- colnames(baterias_msa_075_limpio)

# -------------------------------------------------------
# 4) Diagnósticos del subset: Bartlett, eigenvalues y Horn
# -------------------------------------------------------

matriz_poly_baterias_075 <- psych::polychoric(baterias_msa_075_limpio)$rho
dimnames(matriz_poly_baterias_075) <- list(variables_msa_075, variables_msa_075)

bartlett_baterias_075 <- psych::cortest.bartlett(
	matriz_poly_baterias_075,
	n = nrow(baterias_msa_075_limpio)
)
bartlett_baterias_075

# Eigenvalues de las matrices policoricas

eigenvalues_poly_baterias_075 <- eigen(matriz_poly_baterias_075, only.values = TRUE)$values
eigenvalues_poly_baterias_075

# Analisis paralelo de Horn para subset MSA >= 0.75
horn_baterias_075 <- psych::fa.parallel(
	matriz_poly_baterias_075,
	n.obs = nrow(baterias_msa_075_limpio),
	fa = "fa",
	fm = "minres",
	main = "Analisis paralelo de Horn - baterias MSA >= 0.75"
)


# -------------------------------------------------------
# 5) EFA equivalente en lavaan para el subset MSA >= 0.75
# -------------------------------------------------------

items_baterias_075 <- variables_msa_075
factores_efa_lavaan <- paste0("efa(\"efa1\")*F", 1:3, collapse = " + ")
modelo_efa_lavaan_075 <- paste0(
	factores_efa_lavaan,
	" =~ ",
	paste(items_baterias_075, collapse = " + ")
)

fit_efa_lavaan_075 <- lavaan::sem(
	modelo_efa_lavaan_075,
	data = baterias_msa_075_limpio,
	ordered = TRUE,
	estimator = "WLSMV",
	rotation = "varimax",
	std.lv = TRUE
)

summary(fit_efa_lavaan_075, fit.measures = TRUE, standardized = TRUE)



# -------------------------------------------------------
# 6) CFA inicial con cuatro factores teóricos
# -------------------------------------------------------

modelo_cfa <- '
  # F1: Activismo y consumo ético
  F1 =~ O3_8 + O3_3 + O3_4 + O3_2 + O3_9 + O3_5 + O3_1 + O3_7

  # F2: Planificación y ahorro doméstico
  F2 =~ O2_8 + O1_10 + O2_9 + O2_5 + O2_3

  # F3: Reciclaje en el hogar (O4_4 recodificado)
  F3 =~ O4_6 + O2_6 + O4_1 + O4_4

  # F4: Frugalidad y consumo alternativo (O4_7 y O4_10 recodificados)
  F4 =~ O2_2 + O1_5 + O3_10 + O1_7 + O4_7 + O4_10
'

fit_cfa <- cfa(
  model     = modelo_cfa,
  data      = baterias_msa_075_limpio,
  estimator = "DWLS",          # apropiado para ítems ordinales
  ordered   = TRUE,            # indica a lavaan que todos son ordinales
  std.lv    = TRUE             # fija varianza de factores a 1 (identificación)
)

summary(fit_cfa,
        fit.measures  = TRUE,
        standardized  = TRUE)

# Índices de ajuste por separado
fitMeasures(fit_cfa, c("cfi", "tli", "rmsea", "rmsea.ci.lower",
                        "rmsea.ci.upper", "srmr",
                        "cfi.robust", "tli.robust", "rmsea.robust"))


modindices(fit_cfa, sort = TRUE, maximum.number = 15)


# -------------------------------------------------------
# 7) CFA reespecificado con cuatro factores más compactos
# -------------------------------------------------------

modelo_cfa_v2 <- '
  # F1: Activismo y consumo ético (7 ítems)
  F1 =~ O3_3 + O3_4 + O3_2 + O3_9 + O3_5 + O3_1 + O3_7

  # F2: Planificación y ahorro doméstico (6 ítems)
  F2 =~ O2_8 + O1_10 + O2_9 + O2_5 + O2_3 + O2_2

  # F3: Reciclaje en el hogar (4 ítems)
  F3 =~ O4_6 + O2_6 + O4_1 + O4_4

  # F4: Frugalidad y consumo alternativo (5 ítems)
  F4 =~ O1_5 + O1_7 + O4_10
'

fit_cfa_v2 <- cfa(
  model     = modelo_cfa_v2,
  data      = baterias_msa_075_limpio,
  estimator = "DWLS",
  ordered   = TRUE,
  std.lv    = TRUE
)

summary(fit_cfa_v2,
        fit.measures  = TRUE,
        standardized  = TRUE)

fitMeasures(fit_cfa_v2, c(
  "cfi", "tli",
  "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
  "srmr",
  "cfi.robust", "tli.robust", "rmsea.robust"
))

modindices(fit_cfa_v2, sort = TRUE, maximum.number = 15)


# -------------------------------------------------------
# 8) CFA final de tres factores
# -------------------------------------------------------

modelo_cfa <- '
  F1 =~ O2_12 + O2_11 + O2_13 + O3_7 + O1_8 + O3_3 + O3_2 + O3_4 + O3_1 + O3_5
	F2 =~ O2_3 + O2_4 + O2_5 + O2_9 + O1_10 + O2_2 + O2_14 + O2_1 + O2_8
  F3 =~ O4_4 + O2_6 + O4_6
'

fit_cfa <- lavaan::cfa(
  model = modelo_cfa,
  data = baterias_msa_075_limpio,
  ordered = TRUE,
  estimator = "WLSMV",
  std.lv = TRUE
)

summary(fit_cfa, fit.measures = TRUE, standardized = TRUE)

# Modindices del modelo final (top 20)
modindices(fit_cfa, sort = TRUE, maximum.number = 20)


# -------------------------------------------------------
# 9) Visualización del CFA final
# -------------------------------------------------------

library(semPlot)
# Grafico del modelo CFA estimado (solucion estandarizada)
semPlot::semPaths(
	object = fit_cfa,
	what = "std",
	whatLabels = "std",
	style = "lisrel",
	layout = "tree",
	residuals = FALSE,
	intercepts = FALSE,
	edge.label.cex = 0.8,
	sizeMan = 5,
	sizeLat = 7,
	nCharNodes = 0
)


#-------------------------------
# 10) EFA adicional con 8 factores (lavaan)
#-------------------------------

factores_efa_lavaan_8 <- paste0("efa(\"efa1\")*F", 1:8, collapse = " + ")
modelo_efa_lavaan_8 <- paste0(
	factores_efa_lavaan_8,
	" =~ ",
	paste(names(baterias_msa_075_limpio), collapse = " + ")
)

fit_efa_lavaan_8 <- lavaan::sem(
	modelo_efa_lavaan_8,
	data = baterias_msa_075_limpio,
	ordered = TRUE,
	estimator = "WLSMV",
	rotation = "varimax",
	std.lv = TRUE
)

summary(fit_efa_lavaan_8, fit.measures = TRUE, standardized = TRUE)


# -------------------------------------------------------
# 11) CFA ampliado en 10 factores, reducido a 8 usables
# -------------------------------------------------------

library(lavaan)

# F1 y F2 eliminados (sin ítems limpios)
# F7 eliminado (1 solo ítem)
# 19 ítems retenidos de 39

modelo_cfa_10f <- '
  # F3: Ahorro doméstico activo (5 ítems)
  F3 =~ O2_3 + O2_4 + O2_5 + O2_2 + O2_1

  # F4: Consumo ético y activismo (9 ítems)
  F4 =~ O2_12 + O2_11 + O2_13 + O1_8 +
        O3_3  + O3_2  + O3_5  + O3_9 + O3_8

  # F5: Planificación de compras (3 ítems)
  F5 =~ O2_9 + O1_10 + O2_8

  # F6: Reciclaje en el hogar (2 ítems — mínimo, frágil)
  F6 =~ O2_6 + O4_6

  # F8: Actitudes hacia el reciclaje (2 ítems — mínimo, frágil)
  F8 =~ O4_1 + O4_8

  # F9: Escepticismo y cultura desechable (2 ítems — mínimo, frágil)
  F9 =~ O4_10 + O4_7

  # F10: Consumo alternativo (3 ítems)
  F10 =~ O1_7 + O1_5 + O3_10
'

fit_cfa_10f <- cfa(
  model     = modelo_cfa_10f,
  data      = baterias_msa_075_limpio,
  estimator = "WLSMV",
  ordered   = TRUE,
  std.lv    = TRUE
)

summary(fit_cfa_10f,
        fit.measures  = TRUE,
        standardized  = TRUE)

fitMeasures(fit_cfa_10f, c(
  "cfi", "tli",
  "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
  "srmr"
))

modindices(fit_cfa_10f, sort = TRUE, maximum.number = 15)


# -------------------------------------------------------
# 12) CFA reducido a 8 factores
# -------------------------------------------------------

# 19 ítems eliminados de 39


modelo_cfa_8f <- '
  # F1: Ahorro doméstico activo (5 ítems)
  F1 =~ O2_3 + O2_4 + O2_5 + O2_2 + O2_1

  # F2: Consumo ético y activismo (10 ítems)
  # O1_8 y O3_1 marginales (Δ = .209 y .219)
  F2 =~ O2_12 + O2_11 + O3_7 + O1_8 +
        O3_3  + O3_2  + O3_4 + O3_1 +
        O3_9  + O3_8

'

fit_cfa_8f <- cfa(
  model     = modelo_cfa_8f,
  data      = baterias_msa_075_limpio,
  estimator = "WLSMV",
  ordered   = TRUE,
  std.lv    = TRUE
)

summary(fit_cfa_8f,
        fit.measures  = TRUE,
        standardized  = TRUE)

fitMeasures(fit_cfa_8f, c(
  "cfi", "tli",
  "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
  "srmr"
))

modindices(fit_cfa_8f, sort = TRUE, maximum.number = 15)