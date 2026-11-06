# ------------------------------------------------------------------
# MIT Growth and Development Study
# Modèle linéaire à effets mixtes (ordonnée à l'origine et pentes
# aléatoires avant et après les premières menstruations)
# Traduction en R de modeles_mixtes_residus.sas par modèle Sonnet 5.5 
# de Claude avec adaptations par Alexandre Bureau
# ------------------------------------------------------------------

library(nlme)     # équivalent de PROC MIXED
library(ggplot2)  # graphiques

# ------------------------------------------------------------------
# 1. Lecture des données (DATA step)
# ------------------------------------------------------------------
fat <- read.table("fat.dat", header = FALSE,
                  col.names = c("id", "age", "agemen", "time", "pbf"))

# Variable pour le changement de pente après le temps 0
fat$time_0 <- pmax(fat$time, 0)

# Équivalent de "class id"
fat$id <- factor(fat$id)

# ------------------------------------------------------------------
# 2. Ajustement du modèle (PROC MIXED)
#    - method=reml            -> method = "REML"
#    - random ... type=un     -> matrice G non structurée
#                                (pdSymm/pdLogChol = covariance pleine)
#    Si l'algorithme ne converge pas, essayer :
#    control = lmeControl(opt = "optim", msMaxIter = 200)
# ------------------------------------------------------------------
fit <- lme(pbf ~ time + time_0,
           random = ~ 1 + time + time_0 | id,
           data   = fat,
           method = "REML")

# Option "s" : estimations des effets fixes, et paramètres de covariance
summary(fit)

# Option "chisq" : tests de Wald (khi-deux à 1 ddl) pour les effets fixes
tt   <- summary(fit)$tTable
wald <- data.frame(
  Estimation = tt[, "Value"],
  ErreurType = tt[, "Std.Error"],
  ChiCarre   = (tt[, "Value"] / tt[, "Std.Error"])^2
)
wald$Pr_ChiCarre <- pchisq(wald$ChiCarre, df = 1, lower.tail = FALSE)
print(wald)

# Option "covtest" : nlme ne fournit pas d'erreurs-types pour les
# paramètres de covariance, mais intervals() donne des intervalles de
# confiance approximatifs (écarts-types et corrélations).
intervals(fit, which = "var-cov")

# Options "g" et "gcorr" : matrice G et matrice de corrélation associée
G <- getVarCov(fit, type = "random.effects")
print(G)
print(cov2cor(G))

# Variance résiduelle
s2 <- fit$sigma^2

# ------------------------------------------------------------------
# 3. Matrices X, V_i ; options "v" et "vcorr" (premier sujet, comme SAS)
# ------------------------------------------------------------------
X   <- model.matrix(~ time + time_0, data = fat)   
Z   <- model.matrix(~ time + time_0, data = fat)   # le plan des effets aléatoires est le même
idx <- split(seq_len(nrow(fat)), fat$id)           # lignes de chaque sujet

# V_i = Z_i G Z_i' + sigma^2 I
varmarg <- function(i) {
  Zi <- Z[i, , drop = FALSE]
  Zi %*% G %*% t(Zi) + s2 * diag(length(i))
}

V1 <- varmarg(idx[[1]])
print(V1)
print(cov2cor(V1))

# ------------------------------------------------------------------
# 4. Résidus (options "residual" et "vciry" ; fichier outpm=fatp)
# ------------------------------------------------------------------
beta <- fixef(fit)

# Moyenne prédite (marginale) et résidus bruts marginaux
fat$pred  <- as.numeric(X %*% beta)
fat$resid <- fat$pbf - fat$pred
# On peut aussi obtenir les valeurs prédites des effets fixes seuls avec 
# fitted(fit, level = 0). On vérifie qu'on obtient la même solution.
all.equal(fat$pred, as.numeric(fitted(fit, level = 0)),
                           check.attributes = FALSE)

# Matrice X' V^{-1} X, pour la variance des résidus bruts
A <- Reduce(`+`, lapply(idx, function(i) {
  Xi <- X[i, , drop = FALSE]
  t(Xi) %*% solve(varmarg(i), Xi)
}))
Ainv <- solve(A)

fat$student     <- NA_real_  # résidus "studentisés"
fat$scaleddep   <- NA_real_  # réponse transformée
fat$scaledresid <- NA_real_  # résidus transformés
fat$predt       <- NA_real_  # valeurs prédites transformées

for (i in idx) {
  Xi <- X[i, , drop = FALSE]
  Vi <- varmarg(i)
  
  # Résidus studentisés : r / sqrt(Var(r)), Var(r) = V - X (X'V^-1 X)^-1 X'
  vr <- diag(Vi - Xi %*% Ainv %*% t(Xi))
  fat$student[i] <- fat$resid[i] / sqrt(vr)
  
  # Résidus transformés : L^{-1} r, avec V = L L' (L triangulaire inférieure)
  L <- t(chol(Vi))
  fat$scaleddep[i]   <- forwardsolve(L, fat$pbf[i])
  fat$scaledresid[i] <- forwardsolve(L, fat$resid[i])
  fat$predt[i] <- forwardsolve(L, fat$pred[i])
}

# Moyenne prédite transformée = réponse transformée - résidus transformés
all.equal(fat$predt, fat$scaleddep - fat$scaledresid)

# ------------------------------------------------------------------
# 5. Panneaux de résidus (plots=residualpanel et plots=vcirypanel)
# ------------------------------------------------------------------
panneau <- function(r, pred, temps, titre) {
  op <- par(mfrow = c(2, 2), oma = c(0, 0, 2, 0))
  on.exit(par(op))
  plot(pred, r, xlab = "Valeur prédite", ylab = "Résidu")
  abline(h = 0, lty = 2)
  plot(temps, r, xlab = "Temps", ylab = "Résidu")
  abline(h = 0, lty = 2)
  qqnorm(r, main = "Diagramme quantile-quantile")
  qqline(r)
  hist(r, freq = FALSE, main = "Histogramme", xlab = "Résidu")
  lines(density(r))
  mtext(titre, outer = TRUE, font = 2)
}

panneau(fat$resid,       fat$pred,  fat$time, "Résidus bruts (marginaux)")
panneau(fat$student,     fat$pred,  fat$time, "Résidus studentisés (marginaux)")
panneau(fat$scaledresid, fat$predt, fat$time, "Résidus transformés (Cholesky)")

# ------------------------------------------------------------------
# 6. Lissage loess (PROC LOESS et PROC GAM) avec bandes de confiance
#
#    SAS : select=df1(4) / loess(..., df=4)  -> lisseur ayant environ
#    4 degrés de liberté (nombre équivalent de paramètres).
#    R   : loess(..., enp.target = 4), degré 1 (valeur par défaut de SAS).
#
#    Avec un seul terme lisse, PROC GAM (loess, df=4) et PROC LOESS
#    donnent essentiellement le même ajustement ; une seule fonction
#    sert donc aux deux sections du programme SAS.
# ------------------------------------------------------------------
lisser <- function(donnees, y, x, df = 4) {
  d <- donnees[order(donnees[[x]]), c(y, x)]   # tri croissant selon x
  names(d) <- c("y", "x")
  m <- loess(y ~ x, data = d, degree = 1, enp.target = df)
  p <- predict(m, newdata = d, se = TRUE)
  q <- qt(0.975, p$df)
  data.frame(x = d$x, y = d$y, lisse = p$fit,
             inf = p$fit - q * p$se.fit,
             sup = p$fit + q * p$se.fit)
}

# Résidus bruts vs moyenne prédite
fatb  <- lisser(fat, "resid",       "pred")
# Résidus transformés vs moyenne prédite transformée
fatt  <- lisser(fat, "scaledresid", "predt")
# Résidus bruts vs temps
fatbt <- lisser(fat, "resid",       "time")
# Résidus transformés vs temps
fattt <- lisser(fat, "scaledresid", "time")

# ------------------------------------------------------------------
# 7. Graphiques (PROC GPLOT)
# ------------------------------------------------------------------
graph_lisse <- function(s, xlab, ylab, titre) {
  ggplot(s, aes(x = x, y = y)) +
    geom_point(alpha = 0.4) +
    geom_ribbon(aes(ymin = inf, ymax = sup), alpha = 0.2) +
    geom_line(aes(y = lisse), colour = "red", linewidth = 1) +
    geom_hline(yintercept = 0, linetype = 2) +
    labs(x = xlab, y = ylab, title = titre) +
    theme_bw()
}

graph_lisse(fatt,  "Moyenne prédite transformée", "Résidu transformé",
                  "Résidus transformés vs moyenne prédite transformée")
graph_lisse(fatb,  "Moyenne prédite", "Résidu brut",
                  "Résidus bruts vs moyenne prédite")
graph_lisse(fattt, "Temps", "Résidu transformé",
                  "Résidus transformés vs temps")
graph_lisse(fatbt, "Temps", "Résidu brut",
                  "Résidus bruts vs temps")
