# Esquema final de las escalas y modelos de medida.
# Cargas y correlación dentro de cada escala: AFC de cada escala en la muestra completa
# (las mismas de la Tabla 2). Correlaciones entre escalas: ESEM de 17 ítems (mitad
# de prueba), que no fija en cero las cargas cruzadas.
# Escribe output/figures/esquema_escalas.png y .pdf
suppressPackageStartupMessages({ library(tidyverse); library(here); library(ggforce) })
leer <- function(a) read_csv(here("output", "tables", a), show_col_types = FALSE)
par <- leer("revision_afc_parametros.csv")
cor_esc <- leer("revision_afc_cor_factores.csv")
cor_esem <- leer("informe_esem_cor.csv")
conf <- leer("afc_reducidos_confiabilidad.csv")
apa <- function(x) sub("^-", "−", sub("^(-?)0\\.", "\\1,", formatC(x, digits = 2, format = "f")))

rotulos <- c(
  O2_11 = "Compra productos orgánicos o naturales",
  O2_12 = "Compra productos de material reciclado",
  O3_4  = "Prefiere productos que no dañan el ambiente",
  O3_7  = "Se informa de dónde vienen los productos",
  O3_2  = "Intenta influir en el consumo de otros",
  O3_3  = "Promueve empresas éticas en redes sociales",
  O3_5  = "Hace reclamos colectivos ante el Sernac",
  O3_8  = "Participa en cooperativas de consumo",
  O3_9  = "Participa en marchas o movilizaciones",
  O2_1  = "Apaga luces en ambientes desocupados",
  O2_2  = "Corta el agua al lavarse los dientes",
  O2_3  = "Toma duchas cortas",
  O2_4  = "Deja enfriar alimentos antes de refrigerar",
  O2_5  = "Desenchufa aparatos que no usa",
  O1_10 = "Hace un presupuesto mensual",
  O2_8  = "Planifica la compra de alimentos",
  O2_9  = "Planifica la compra de vestuario")
facs <- c(compra_sust = "Compra\nsustentable", consumo_pol = "Consumo\npolítico",
          ahorro = "Ahorro\ndoméstico", planificacion = "Planificación\nde compras")
escala_de <- c(compra_sust = 1, consumo_pol = 1, ahorro = 2, planificacion = 2)

# Posiciones verticales: un espacio entre factores y uno mayor entre escalas
it <- par %>% transmute(factor = lhs, item = rhs, carga = std) %>%
  mutate(factor = factor(factor, levels = names(facs))) %>% arrange(factor)
y <- numeric(nrow(it)); pos <- 0
for (i in seq_len(nrow(it))) {
  if (i > 1 && it$factor[i] != it$factor[i - 1])
    pos <- pos + if (escala_de[as.character(it$factor[i])] != escala_de[as.character(it$factor[i - 1])]) 2.2 else 1
  y[i] <- -pos; pos <- pos + 1
}
it$y <- y
fy <- it %>% group_by(factor) %>% summarise(y = mean(y), ymin = min(y), ymax = max(y), .groups = "drop") %>%
  mutate(factor = as.character(factor)) %>%
  left_join(conf %>% select(factor, omega), by = "factor")

x_it <- 0; ancho_it <- 11; x_fac <- 16; rx <- 2.1; ry <- 1.0
esc <- tibble(escala = c("Escala de consumo sustentable y político (9 ítems)",
                         "Escala de prácticas domésticas (8 ítems)"),
              ymin = c(min(it$y[escala_de[as.character(it$factor)] == 1]), min(it$y[escala_de[as.character(it$factor)] == 2])) - 0.75,
              ymax = c(max(it$y[escala_de[as.character(it$factor)] == 1]), max(it$y[escala_de[as.character(it$factor)] == 2])) + 1.35)

# Correlaciones: dentro de la escala (AFC) y entre escalas (ESEM)
dentro <- tibble(f1 = c("compra_sust", "ahorro"), f2 = c("consumo_pol", "planificacion"),
                 r = cor_esc$r[match(c("Consumo sustentable y político, dos factores", "Prácticas domésticas, dos factores"), cor_esc$escala)],
                 tipo = "Dentro de la escala")
entre <- cor_esem %>% filter(!(factor1 == "compra_sust" & factor2 == "consumo_pol"),
                             !(factor1 == "ahorro" & factor2 == "planificacion")) %>%
  transmute(f1 = factor1, f2 = factor2, r, tipo = "Entre escalas")
cors <- bind_rows(dentro, entre) %>%
  mutate(y1 = fy$y[match(f1, fy$factor)], y2 = fy$y[match(f2, fy$factor)],
         span = abs(y1 - y2), cx = x_fac + rx + 1.2 + 0.55 * span) %>%
  arrange(span)
bez <- cors %>% mutate(id = row_number()) %>%
  rowwise() %>% reframe(id, tipo, x = c(x_fac + rx, cx, x_fac + rx), y = c(y1, (y1 + y2) / 2, y2))
etq <- cors %>% mutate(x = 0.5 * (x_fac + rx) + 0.5 * cx, y = (y1 + y2) / 2)

g <- ggplot() +
  geom_rect(data = esc, aes(xmin = -0.4, xmax = x_fac + rx + 0.5, ymin = ymin, ymax = ymax),
            fill = c("grey93", "grey87"), colour = NA) +
  geom_text(data = esc, aes(x = 0, y = ymax - 0.45, label = escala), hjust = 0, fontface = "bold",
            size = 3.1, family = "serif") +
  geom_segment(data = it %>% mutate(fy = fy$y[match(as.character(factor), fy$factor)]),
               aes(x = x_fac - rx, y = fy, xend = x_it + ancho_it, yend = y),
               arrow = arrow(length = unit(0.11, "cm"), type = "closed"), linewidth = 0.3, colour = "grey25") +
  geom_label(data = it %>% mutate(fy = fy$y[match(as.character(factor), fy$factor)]),
             aes(x = x_it + ancho_it + 0.42 * (x_fac - rx - x_it - ancho_it), y = y + 0.42 * (fy - y), label = apa(carga)),
             size = 2.4, family = "serif", label.size = 0, fill = "white", label.padding = unit(0.05, "lines")) +
  geom_tile(data = it, aes(x = x_it + ancho_it / 2, y = y), width = ancho_it, height = 0.78,
            fill = "white", colour = "grey30", linewidth = 0.3) +
  geom_text(data = it, aes(x = x_it + 0.08, y = y, label = paste0(str_replace(item, "_", "."), "  ", rotulos[item])),
            hjust = 0, size = 2.45, family = "serif") +
  geom_ellipse(data = fy, aes(x0 = x_fac, y0 = y, a = rx, b = ry, angle = 0), fill = "white",
               colour = "grey20", size = 0.45) +
  geom_text(data = fy, aes(x = x_fac, y = y + 0.22, label = facs[factor]), size = 2.7, family = "serif",
            fontface = "bold", lineheight = 0.85) +
  geom_text(data = fy, aes(x = x_fac, y = y - 0.6, label = paste0("ω = ", apa(omega))), size = 2.3, family = "serif") +
  geom_bezier(data = bez, aes(x = x, y = y, group = id, linetype = tipo), linewidth = 0.4,
              arrow = arrow(length = unit(0.1, "cm"), ends = "both", type = "closed")) +
  geom_label(data = etq, aes(x = x, y = y, label = apa(r)), size = 2.4, family = "serif",
             label.size = 0, fill = "white", label.padding = unit(0.08, "lines")) +
  scale_linetype_manual(values = c("Dentro de la escala" = "solid", "Entre escalas" = "22"),
                        labels = c("Dentro de la escala" = "Correlación dentro de la escala (AFC)",
                                   "Entre escalas" = "Correlación entre escalas (ESEM)"), name = NULL) +
  coord_fixed(xlim = c(-0.4, 0.5 * (x_fac + rx) + 0.5 * max(cors$cx) + 0.8), clip = "off") +
  theme_void(base_family = "serif") +
  theme(legend.position = "bottom", legend.text = element_text(size = 8),
        plot.margin = margin(4, 4, 4, 4))
dir.create(here("output", "figures"), showWarnings = FALSE)
ggsave(here("output", "figures", "esquema_escalas.png"), g, width = 6.5, height = 6.9, dpi = 300, bg = "white")
ggsave(here("output", "figures", "esquema_escalas.pdf"), g, width = 6.5, height = 6.9, device = cairo_pdf)
