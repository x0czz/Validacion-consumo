# Sensibilidad: correlaciones entre factores y con variables externas (actitudes políticas,
# educación, situación económica, sexo, edad y NSE) estimadas con el AFC de cada escala,
# el AFC conjunto de cuatro factores y el ESEM de la misma estructura (muestra completa).
# El ESEM se estima en dos pasos: primero sin covariables y luego, con su modelo de medida
# fijo (cargas rotadas, umbrales y correlaciones entre factores), se estiman solo las
# correlaciones con cada covariable. Incluir las covariables directamente en el ESEM altera
# la rotación y produce soluciones impropias.
# Escribe output/tables/sensibilidad_esem_covariables.csv y sensibilidad_esem_factores.csv
suppressPackageStartupMessages({library(tidyverse); library(haven); library(lavaan); library(here)})
db <- readRDS(here("input","data","proc","db_proc.rds"))
original <- read_sav(here("input","data","original","Encuesta Sociedad de Consumo 2023.sav"))
num <- function(x) as.numeric(zap_labels(x))
items <- db %>% select(matches("^O[1-4]_\\d+$")) %>% mutate(across(everything(), num))
motivo <- function(v) as.character(as_factor(original[[v]]))
ext <- tibble(C3_14 = num(original$C3_14), M9 = num(original$M9), M4 = num(original$M4),
  ingreso = num(original$E2),
  deuda_alimentos = as.numeric(coalesce(motivo("M16R_1") == "Supermercado/Alimentos", FALSE) |
                               coalesce(motivo("M16R_2") == "Supermercado/Alimentos", FALSE)),
  mas_endeudado = as.numeric(num(original$M15) == 1),
  mujer = as.numeric(num(db$SEXO) == 2),
  edad3 = as.numeric(cut(num(db$EDADR), c(1,3,5,7))),
  nse3 = as.numeric(cut(num(db$NSE), c(0,3,5,7))))
ext$ingreso[ext$ingreso > 5] <- NA
d <- bind_cols(items, ext)
stopifnot(all(d$C3_14 <= 5, na.rm=TRUE))
facs <- c("compra_sust","consumo_pol","ahorro","planificacion")
it <- list(compra_sust=c("O2_11","O2_12","O3_4","O3_7"), consumo_pol=c("O3_2","O3_3","O3_5","O3_8","O3_9"),
           ahorro=c("O2_1","O2_2","O2_3","O2_4","O2_5"), planificacion=c("O1_10","O2_8","O2_9"))
items17 <- unlist(it)
cfa_esc <- list(pub = sprintf("%s =~ %s", facs[1:2], map_chr(it[1:2], paste, collapse=" + ")),
                dom = sprintf("%s =~ %s", facs[3:4], map_chr(it[3:4], paste, collapse=" + ")))
cfa_conj <- sprintf("%s =~ %s", facs, map_chr(it, paste, collapse=" + "))
objetivo <- matrix(0, 17, 4, dimnames=list(items17, facs)); for (f in facs) objetivo[it[[f]], f] <- NA
esem <- paste(paste0('efa("b")*', facs, collapse=" + "), "=~", paste(items17, collapse=" + "))
cont_f <- function(v) sprintf("%s_l =~ 1*%s\n%s ~~ 0*%s", v, v, v, v)
bin_f  <- function(v) sprintf("%s_l =~ 1*%s\n%s_l ~~ 1*%s_l", v, v, v, v)
sets <- list(
  politicas = list(cont = c("C3_14","M9","M4"), bin = character(0)),
  ingreso   = list(cont = "ingreso", bin = character(0)),
  deuda     = list(cont = character(0), bin = "deuda_alimentos"),
  endeud    = list(cont = character(0), bin = "mas_endeudado"),
  grupos    = list(cont = c("edad3","nse3"), bin = "mujer"))
est <- function(m, vars, tipo) {
  dd <- d %>% filter(if_all(all_of(c(vars$cont, vars$bin)), ~ !is.na(.x)))
  bloque <- paste(c(map_chr(vars$cont, cont_f), map_chr(vars$bin, bin_f)), collapse="\n")
  ords <- c(intersect(items17, str_extract_all(paste(m, collapse=" "), "O\\d_\\d+")[[1]]), vars$bin)
  mod <- paste(c(m, bloque), collapse="\n")
  if (tipo == "ESEM") mod <- paste(c(esem_fijo, bloque), collapse="\n")
  f <- cfa(mod, data = dd, ordered = ords, estimator = "WLSMV")
  lv <- paste0(c(vars$cont, vars$bin), "_l")
  standardizedSolution(f) %>% filter(op == "~~", (lhs %in% facs & rhs %in% lv) | (rhs %in% facs & lhs %in% lv)) %>%
    transmute(modelo = tipo, factor = if_else(lhs %in% facs, lhs, rhs), variable = if_else(lhs %in% facs, rhs, lhs),
              r = est.std, ic_inf = ci.lower, ic_sup = ci.upper, p = pvalue)
}
# ESEM en dos pasos: se estima el ESEM sin covariables (muestra completa) y se fija su
# modelo de medida (cargas rotadas, umbrales y correlaciones entre factores); luego solo
# se estiman las correlaciones de los factores con cada covariable.
f_esem0 <- cfa(esem, data = d[, items17], ordered = items17, estimator = "WLSMV",
               rotation = "target", rotation.args = list(target = objetivo))
pe <- parameterEstimates(f_esem0)
L <- pe %>% filter(op == "=~"); TH <- pe %>% filter(op == "|"); PH <- pe %>% filter(op == "~~", lhs %in% facs, rhs %in% facs)
esem_fijo <- c(
  map_chr(facs, function(fa) paste0(fa, " =~ ", paste(sprintf("%.6f*%s", L$est[L$lhs == fa], L$rhs[L$lhs == fa]), collapse = " + "))),
  sprintf("%s | %.6f*%s", TH$lhs, TH$est, TH$rhs),
  sprintf("%s ~~ %.6f*%s", PH$lhs, PH$est, PH$rhs))
res <- imap_dfr(sets, function(v, nm) bind_rows(
  bind_rows(est(cfa_esc$pub, v, "AFC por escala"), est(cfa_esc$dom, v, "AFC por escala")),
  est(cfa_conj, v, "AFC conjunto"), est(esem, v, "ESEM")))
write_csv(res, here("output", "tables", "sensibilidad_esem_covariables.csv"))
# correlaciones entre factores, muestra completa
fc <- function(m, tipo) { mod <- paste(m, collapse="\n"); dd <- d[, items17]
  f <- if (tipo == "ESEM") cfa(mod, data = dd, ordered = items17, estimator = "WLSMV", rotation = "target",
       rotation.args = list(target = objetivo)) else cfa(mod, data = dd, ordered = items17, estimator = "WLSMV"); standardizedSolution(f) %>% filter(op=="~~", lhs %in% facs, rhs %in% facs, lhs != rhs) %>%
  transmute(tipo, factor1 = lhs, factor2 = rhs, r = est.std) }
write_csv(bind_rows(fc(cfa_conj, "AFC conjunto"), fc(esem, "ESEM")) %>% pivot_wider(names_from = tipo, values_from = r),
          here("output", "tables", "sensibilidad_esem_factores.csv"))
