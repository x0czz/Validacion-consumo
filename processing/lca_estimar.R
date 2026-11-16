# Estimación de modelos de clases latentes (LCA) — enumeración de clases
# Se llama desde processing/clases_latentes.qmd. Guarda output/models/lca_enumeracion.rds
suppressPackageStartupMessages({ library(dplyr); library(poLCA); library(here); library(haven) })

datos <- readRDS(here("input", "data", "proc", "db_proc.rds"))

items_A <- c("O2_11", "O2_12", "O3_4", "O3_7",               # compra sustentable
             "O3_2", "O3_3", "O3_5", "O3_8", "O3_9",         # consumo político
             "O2_1", "O2_2", "O2_3", "O2_4", "O2_5",         # ahorro doméstico
             "O1_10", "O2_8", "O2_9")                        # planificación de compras
items_O4 <- c("O4_2", "O4_3", "O4_5",                        # facilidad para reciclar
              "O4_1", "O4_7", "O4_8")                        # valoración del reciclaje
items_B <- c(items_A, items_O4)
# Variante de control: un ítem de actitud por dimensión, para evitar la dependencia
# local entre ítems de O4 casi redundantes (p. ej., O4_3 y O4_5)
items_C <- c(items_A, "O4_3", "O4_1")

# poLCA requiere categorías enteras consecutivas desde 1
recodificar <- function(x) as.integer(factor(as.numeric(zap_labels(x))))
lca_datos <- datos %>% mutate(across(all_of(items_B), recodificar))

# Una estimación por cada inicio aleatorio; se guarda la de mayor verosimilitud
# y cuántos inicios replican ese máximo (criterio de convergencia global)
estimar_k <- function(items, k, inicios = 100, semilla = 20231) {
  f <- as.formula(paste0("cbind(", paste(items, collapse = ", "), ") ~ 1"))
  set.seed(semilla + k)
  ajustes <- lapply(seq_len(inicios), function(i)
    tryCatch(poLCA(f, data = lca_datos, nclass = k, maxiter = 5000, nrep = 1, verbose = FALSE),
             error = function(e) NULL))
  ajustes <- Filter(Negate(is.null), ajustes)
  ll <- sapply(ajustes, `[[`, "llik")
  mejor <- ajustes[[which.max(ll)]]
  mejor$replicas <- sum(abs(ll - max(ll)) < 0.01)
  mejor$inicios <- length(ll)
  mejor
}

indices <- function(m) {
  n <- m$Nobs; p <- m$npar; ll <- m$llik
  post <- m$posterior
  ent <- if (ncol(post) == 1) NA else
    1 - sum(-post * log(pmax(post, 1e-300))) / (n * log(ncol(post)))
  tibble(clases = ncol(post), LL = ll, npar = p,
         AIC = -2 * ll + 2 * p, BIC = -2 * ll + p * log(n),
         aBIC = -2 * ll + p * log((n + 2) / 24), CAIC = -2 * ll + p * (log(n) + 1),
         entropia = ent, clase_min = min(m$P),
         replicas = m$replicas, inicios = m$inicios)
}

ks <- 1:8
modelos <- list(
  A = lapply(ks, function(k) estimar_k(items_A, k)),
  B = lapply(ks, function(k) estimar_k(items_B, k)),
  C = lapply(ks, function(k) estimar_k(items_C, k))
)
enumeracion <- bind_rows(
  bind_rows(lapply(modelos$A, indices)) %>% mutate(modelo = "A: prácticas (17 ítems)"),
  bind_rows(lapply(modelos$B, indices)) %>% mutate(modelo = "B: prácticas + actitudes (23 ítems)"),
  bind_rows(lapply(modelos$C, indices)) %>% mutate(modelo = "C: prácticas + 2 actitudes (19 ítems)")
)

dir.create(here("output", "models"), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(modelos = modelos, enumeracion = enumeracion, items_A = items_A,
             items_B = items_B, items_C = items_C, items_O4 = items_O4, lca_datos = lca_datos),
        here("output", "models", "lca_enumeracion.rds"))
