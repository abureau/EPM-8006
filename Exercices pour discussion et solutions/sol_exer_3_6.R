#### Environnement de travail
setwd("C:\\Users\\denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


#### Charger les donnees
lalonde = read.csv("lalonde.csv");


#### Charger les modules necessaires
require(tableone); # Statistiques descriptives
require(rms); # Splines cubiques et diagnostics
require(sandwich); # Estimateur robuste
require(MASS); # Residus studentises


#### Statistiques descriptives selon l'exposition
print(CreateTableOne(vars = c("age", "educ", "black", "hispan", "married",
                              "nodegree", "re74", "re75"),
                     factorVars = c("black", "hispan", "married", "nodegree"),
                     strata = "treat", data = lalonde), test = FALSE, smd = TRUE);


#### Ajout d'un identifiant unique
lalonde$id = 1:nrow(lalonde);


#### Modele de regression lineaire
fit = lm(re78 ~ treat + treat*re74 + rcs(age) + rcs(educ) + black + hispan +
                married + nodegree + re74 + rcs(re75), data = lalonde);


#### Verification des hypotheses

### 1. Linearite
sr = studres(fit);
plot(lalonde$re74, sr, pch = 16);
lines(lowess(y = sr, x = lalonde$re74), col = "brown", lwd = 3);
abline(h = 0, lwd = 2, col = "purple");
# Il semble y avoir une tendance residuelle, mais 
# probablement en raison d'une valeur extreme.


### 2. Independance - ok selon nos connaissances

### 3. Homoscedasticite
plot(y = abs(sr), x = fit$fitted);
lines(lowess(y = abs(sr), x = fit$fitted), col = "brown", lwd = 3);
# Tendance a la hausse, mais peut-etre en raison d'une obs extreme

plot(y = abs(sr), x = lalonde$age);
lines(lowess(y = abs(sr), x = lalonde$age), col = "brown", lwd = 3);
# Ok

plot(y = abs(sr), x = lalonde$educ);
lines(lowess(y = abs(sr), x = lalonde$educ), col = "brown", lwd = 3);
# Tendance a la hausse, mais peut-etre en raison d'une obs extreme

plot(y = abs(sr), x = lalonde$re74);
lines(lowess(y = abs(sr), x = lalonde$re74), col = "brown", lwd = 3);
# Legere tendance a la hausse

plot(y = abs(sr), x = lalonde$re75);
lines(lowess(y = abs(sr), x = lalonde$re75), col = "brown", lwd = 3);
# Legere tendance a la hausse


tapply(sr, lalonde$black, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde$hispan, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde$married, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde$nodegree, sd, na.rm = TRUE);
# ok


### Normalite: pas important avec notre n
qqnorm(sr); qqline(sr, col = "red", lwd = 2);
# Plutot bien en general, sauf obs extreme


### 5. Multicollinearite
round(vif(fit), 2);
# Vif de treat et treat:re74 < 10 = ok


### 6. Donnees influentes
dfb = dfbetas(fit);
head(dfb, 1);
round(summary(dfb[,2]), 2);
round(summary(dfb[,20]), 2);
# Certaines valeurs extremes et influentes
# Dont une en particulier avec un dfb de 2.29

lalonde[dfb[,20] > 2,];






#### Nouveau modele avec une observation en moins
lalonde2 = lalonde[-(lalonde$id == 182),];

#### Modele de regression lineaire
fit = lm(re78 ~ treat + treat*re74 + rcs(age) + rcs(educ) + black + hispan +
                married + nodegree + re74 + rcs(re75), data = lalonde2);


#### Verification des hypotheses

### 1. Linearite
sr = studres(fit);
plot(lalonde2$re74, sr, pch = 16);
lines(lowess(y = sr, x = lalonde2$re74), col = "brown", lwd = 3);
abline(h = 0, lwd = 2, col = "purple");
# Il semble y avoir une tendance residuelle, mais 
# probablement en raison d'une valeur extreme.


### 2. Independance - ok selon nos connaissances

### 3. Homoscedasticite
plot(y = abs(sr), x = fit$fitted);
lines(lowess(y = abs(sr), x = fit$fitted), col = "brown", lwd = 3);
# Tendance a la hausse, mais peut-etre en raison d'une obs extreme

plot(y = abs(sr), x = lalonde2$age);
lines(lowess(y = abs(sr), x = lalonde2$age), col = "brown", lwd = 3);
# Ok

plot(y = abs(sr), x = lalonde2$educ);
lines(lowess(y = abs(sr), x = lalonde2$educ), col = "brown", lwd = 3);
# Tendance a la hausse, mais peut-etre en raison d'une obs extreme

plot(y = abs(sr), x = lalonde2$re74);
lines(lowess(y = abs(sr), x = lalonde2$re74), col = "brown", lwd = 3);
# Legere tendance a la hausse

plot(y = abs(sr), x = lalonde2$re75);
lines(lowess(y = abs(sr), x = lalonde2$re75), col = "brown", lwd = 3);
# Legere tendance a la hausse


tapply(sr, lalonde2$black, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde2$hispan, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde2$married, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde2$nodegree, sd, na.rm = TRUE);
# ok


### Normalite: pas important avec notre n
qqnorm(sr); qqline(sr, col = "red", lwd = 2);
# Plutot bien en general, sauf obs extreme


### 5. Multicollinearite
round(vif(fit), 2);
# Vif de treat et treat:re74 < 10 = ok


### 6. Donnees influentes
dfb = dfbetas(fit);
head(dfb, 1);
round(summary(dfb[,2]), 2);
round(summary(dfb[,20]), 2);
# Certaines valeurs extremes et influentes
# Dont une en particulier avec un dfb de 2.28

lalonde[dfb[,20] > 2,];






#### Nouveau modele avec une observation en moins
lalonde3 = lalonde[!(lalonde$id %in% c(181, 182)),];
nrow(lalonde3);

#### Modele de regression lineaire
fit = lm(re78 ~ treat + treat*re74 + rcs(age) + rcs(educ) + black + hispan +
                married + nodegree + re74 + rcs(re75), data = lalonde3);


#### Verification des hypotheses

### 1. Linearite
sr = studres(fit);
plot(lalonde3$re74, sr, pch = 16);
lines(lowess(y = sr, x = lalonde3$re74), col = "brown", lwd = 3);
abline(h = 0, lwd = 2, col = "purple");
# Il semble y avoir une legere tendance residuelle, mais 
# probablement en raison d'une valeur extreme.


### 2. Independance - ok selon nos connaissances

### 3. Homoscedasticite
plot(y = abs(sr), x = fit$fitted);
lines(lowess(y = abs(sr), x = fit$fitted), col = "brown", lwd = 3);
# Tendance a la hausse

plot(y = abs(sr), x = lalonde3$age);
lines(lowess(y = abs(sr), x = lalonde3$age), col = "brown", lwd = 3);
# Ok

plot(y = abs(sr), x = lalonde3$educ);
lines(lowess(y = abs(sr), x = lalonde3$educ), col = "brown", lwd = 3);
# Tendance a la hausse, mais peut-etre en raison d'une obs extreme

plot(y = abs(sr), x = lalonde3$re74);
lines(lowess(y = abs(sr), x = lalonde3$re74), col = "brown", lwd = 3);
# Legere tendance a la hausse

plot(y = abs(sr), x = lalonde3$re75);
lines(lowess(y = abs(sr), x = lalonde3$re75), col = "brown", lwd = 3);
# Tres legere tendance a la hausse


tapply(sr, lalonde3$black, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde3$hispan, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde3$married, sd, na.rm = TRUE);
# ok

tapply(sr, lalonde3$nodegree, sd, na.rm = TRUE);
# ok


### Normalite: pas important avec notre n
qqnorm(sr); qqline(sr, col = "red", lwd = 2);
# Plutot bien en general, sauf obs extreme


### 5. Multicollinearite
round(vif(fit), 2);
# Vif de treat et treat:re74 < 10 = ok


### 6. Donnees influentes
dfb = dfbetas(fit);
head(dfb, 1);
round(summary(dfb[,2]), 2);
round(summary(dfb[,20]), 2);
# Certaines valeurs extremes et influentes persistent, mais beaucoup moins pire
# Je cesse de retirer des observations a ce stade, mais dans une vraie analyse,
# ce serait pertinent de continuer en analyse de sensibilite

# Je vais utiliser un estimateur robuste de la variance comme il semble
# subsister un probleme d'heteroscedasticite


#### Tests d'hypotheses et comparaisons de moyennes

VCOV.robuste = sandwich(fit); # Variance covariance sandwich

## Test d'hypotheses simultanees, strategie 2
L = matrix(c(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1), nrow = 2, byrow = TRUE);
LB = L%*%coef(fit);
chisq = t(LB)%*%solve(L%*%VCOV.robuste%*%t(L))%*%LB
pval = pchisq(chisq, df = nrow(L), lower.tail = FALSE);
data.frame(chisq, df = nrow(L), pval);
# Association entre le traitement et le revenu en 78

## Comparaisons de moyennes
L = matrix(c(0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2000,
             0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5000), nrow = 3, byrow = TRUE);
LB = coef(fit)%*%t(L);
se = sqrt(diag(L%*%VCOV.robuste%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), se, LL = t(LL), UL = t(UL), chisq, df = 1, pval);

# Le traitement est associe a une hausse de revenu pour les
# gens sans revenu (difference de revenu en 78 = 3230$,
# IC a 95%: 1708$ a 4754$). Pour ceux ayant un revenu de 2000$,
# le programme est aussi associe a une hausse, bien que plus
# modeste (difference = 1824$, IC a 95%: 456$ a 3192$).
# Pour les gens ayant un revenu de 5000$, 
# les donnees ne permettent pas de conclure
# concernant l'efficacite du programme,
# puisqu'elles sont a la fois compatible avec une
# association negative, nulle et positive
# (difference =  -286$, IC a 95%: -1685$ a 1114$).
