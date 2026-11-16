# Esquema final de las escalas: AFC conjunto de cuatro factores en la muestra completa
# (cargas estandarizadas y correlaciones entre factores). Escribe
# output/tables/esquema_cargas.csv, output/tables/esquema_correlaciones.csv
suppressPackageStartupMessages({ library(tidyverse); library(haven); library(here); library(lavaan) })
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
items <- db_proc %>% select(matches("^O[1-3]_\\d+$")) %>% mutate(across(everything(), ~ as.numeric(zap_labels(.x))))
m <- 'compra_sust   =~ O2_11 + O2_12 + O3_4 + O3_7
      consumo_pol   =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9
      ahorro        =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
      planificacion =~ O1_10 + O2_8 + O2_9'
f <- cfa(m, data = items, ordered = TRUE, estimator = "WLSMV")
st <- standardizedSolution(f)
write_csv(st %>% filter(op == "=~") %>% transmute(factor = lhs, item = rhs, carga = est.std),
          here("output", "tables", "esquema_cargas.csv"))
write_csv(st %>% filter(op == "~~", lhs != rhs, lhs %in% c("compra_sust","consumo_pol","ahorro","planificacion")) %>%
            transmute(factor1 = lhs, factor2 = rhs, r = est.std, p = pvalue),
          here("output", "tables", "esquema_correlaciones.csv"))
