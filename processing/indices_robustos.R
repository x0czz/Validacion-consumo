# Índices de ajuste escalados y robustos (Savalei, 2021) de las escalas finales.
# Escribe output/tables/indices_robustos.csv
suppressPackageStartupMessages({ library(tidyverse); library(haven); library(here); library(lavaan) })
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
items <- db_proc %>% select(matches("^O[1-3]_\\d+$")) %>% mutate(across(everything(), ~ as.numeric(zap_labels(.x))))
idx_m1 <- readRDS(here("output", "models", "afe_5factores.rds"))$idx_mitad1
modelos <- list("Consumo sustentable y político" = 'compra_sust =~ O2_11 + O2_12 + O3_4 + O3_7
                                                   consumo_pol =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9',
                "Prácticas domésticas" = 'ahorro =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
                                          planificacion =~ O1_10 + O2_8 + O2_9')
muestras <- list("Mitad de prueba" = items[-idx_m1, ], "Muestra completa" = items)
res <- imap_dfr(modelos, function(m, nm) imap_dfr(muestras, function(d, mu) {
  fm <- fitMeasures(cfa(m, data = d, ordered = TRUE, estimator = "WLSMV"),
                    c("cfi.scaled", "tli.scaled", "rmsea.scaled", "cfi.robust", "tli.robust", "rmsea.robust",
                      "rmsea.ci.lower.robust", "rmsea.ci.upper.robust"))
  tibble(escala = nm, muestra = mu, !!!as.list(fm))
}))
write_csv(res, here("output", "tables", "indices_robustos.csv"))
print(res %>% mutate(across(where(is.numeric), ~ round(.x, 3))) %>% as.data.frame())
