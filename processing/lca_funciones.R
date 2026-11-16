# Funciones auxiliares para describir y diagnosticar soluciones de clases latentes
suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(purrr) })

# Media esperada de cada ítem en cada clase, reescalada a 0-1
# (0 = categoría más baja, 1 = más alta), para comparar ítems con distinto n.º de categorías
perfil_clases <- function(m) {
  imap_dfr(m$probs, function(pr, item) {
    k <- ncol(pr)
    tibble(item = item, clase = seq_len(nrow(pr)),
           media01 = as.vector(pr %*% (seq_len(k) - 1)) / (k - 1))
  })
}

# Residuos bivariados (BVR): X² de Pearson de cada par de ítems, observado vs. esperado
# por el modelo, dividido por sus grados de libertad. Valores > 3,84 sugieren
# dependencia local no explicada por las clases.
residuos_bivariados <- function(m, datos, items) {
  P <- m$P; pr <- m$probs
  pares <- combn(items, 2, simplify = FALSE)
  map_dfr(pares, function(par) {
    a <- par[1]; b <- par[2]
    obs <- table(factor(datos[[a]], levels = seq_len(ncol(pr[[a]]))),
                 factor(datos[[b]], levels = seq_len(ncol(pr[[b]]))))
    esp <- Reduce(`+`, lapply(seq_along(P), function(c)
      P[c] * outer(pr[[a]][c, ], pr[[b]][c, ]))) * nrow(datos)
    x2 <- sum((obs - esp)^2 / pmax(esp, 1e-10))
    gl <- (nrow(obs) - 1) * (ncol(obs) - 1)
    tibble(item1 = a, item2 = b, BVR = x2 / gl)
  })
}

# Calidad de la clasificación: probabilidad posterior media de las personas asignadas a cada clase
clasificacion <- function(m) {
  modal <- m$predclass
  tibble(clase = seq_along(m$P), proporcion = m$P,
         n_modal = as.vector(table(factor(modal, levels = seq_along(m$P)))),
         AvePP = sapply(seq_along(m$P), function(c) mean(m$posterior[modal == c, c])))
}

# ---------------------------------------------------------------------------
# Enfoque de tres pasos con corrección por máxima verosimilitud (Vermunt, 2010)
#   Paso 1: modelo de medida sin covariables (ya estimado).
#   Paso 2: asignación modal W y matriz de error de clasificación
#           D[s, w] = P(W = w | X = s), calculada con las probabilidades posteriores.
#   Paso 3: regresión logística multinomial de la clase latente X sobre las
#           covariables Z, donde la verosimilitud de cada persona es
#           L_i = sum_s P(X = s | Z_i) * D[s, W_i].
#           Así la clase asignada se trata como un indicador imperfecto de la clase real.
# ---------------------------------------------------------------------------
matriz_error <- function(m) {
  post <- m$posterior; W <- m$predclass; K <- ncol(post)
  D <- sapply(seq_len(K), function(w) colSums(post[W == w, , drop = FALSE])) / colSums(post)
  dimnames(D) <- list(real = seq_len(K), asignada = seq_len(K))
  D  # filas: clase real s; columnas: clase asignada w; cada fila suma 1
}

tres_pasos_ml <- function(m, Z, ref) {
  # m: modelo poLCA; Z: matriz de diseño (con intercepto); ref: clase de referencia
  K <- length(m$P); D <- matriz_error(m); W <- m$predclass
  otras <- setdiff(seq_len(K), ref); p <- ncol(Z)
  prob_clase <- function(theta, Zm = Z) {
    B <- matrix(theta, nrow = p)                       # p x (K-1)
    eta <- matrix(0, nrow(Zm), K); eta[, otras] <- Zm %*% B
    eta <- eta - apply(eta, 1, max)
    exp(eta) / rowSums(exp(eta))
  }
  nll <- function(theta) -sum(log(rowSums(prob_clase(theta) * t(D[, W]))))
  inicio <- rep(0, p * (K - 1))
  ajuste <- optim(inicio, nll, method = "BFGS", control = list(maxit = 2000, reltol = 1e-12))
  H <- numDeriv::hessian(nll, ajuste$par)
  V <- solve(H)
  list(coef = matrix(ajuste$par, nrow = p, dimnames = list(colnames(Z), otras)),
       vcov = V, loglik = -ajuste$value, convergencia = ajuste$convergence,
       prob_clase = prob_clase, D = D, ref = ref, otras = otras)
}

# Prueba de Wald conjunta para un conjunto de columnas de Z (todas las clases a la vez)
wald_covariable <- function(ajuste, columnas) {
  p <- nrow(ajuste$coef); K1 <- ncol(ajuste$coef)
  idx <- as.vector(outer(match(columnas, rownames(ajuste$coef)), (seq_len(K1) - 1) * p, `+`))
  b <- as.vector(ajuste$coef)[idx]; V <- ajuste$vcov[idx, idx]
  W <- as.numeric(t(b) %*% solve(V, b))
  tibble(wald = W, gl = length(idx), p = pchisq(W, length(idx), lower.tail = FALSE))
}

# Probabilidad predicha de pertenecer a cada clase en cada grupo de una covariable,
# promediando sobre la muestra con esa covariable fijada en el grupo y las demás
# en sus valores observados (probabilidad marginal promedio). IC 95% por simulación
# de los coeficientes a partir de su distribución normal asintótica.
prob_predichas <- function(ajuste, Z, columnas_grupo, nombres_clase, n_sim = 2000, semilla = 1) {
  niveles <- c(NA, columnas_grupo)  # NA = categoría de referencia (todas las dummies en 0)
  calcular <- function(theta) {
    sapply(niveles, function(niv) {
      Zg <- Z; Zg[, columnas_grupo] <- 0
      if (!is.na(niv)) Zg[, niv] <- 1
      colMeans(ajuste$prob_clase(theta, Zg))
    })
  }
  est <- calcular(as.vector(ajuste$coef))
  set.seed(semilla)
  sims <- MASS::mvrnorm(n_sim, as.vector(ajuste$coef), ajuste$vcov)
  sim <- array(apply(sims, 1, calcular), dim = c(dim(est), n_sim))
  dimnames(est) <- list(nombres_clase, NULL)
  list(est = est, inf = apply(sim, 1:2, quantile, 0.025), sup = apply(sim, 1:2, quantile, 0.975))
}
