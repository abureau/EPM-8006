#**************************************
# 6.1 EXEMPLE DE SOLUTION             *
#*************************************/


### Repertoire de travail
setwd("C:\\Users\\Denis\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


### Importation des donnees
ds = read.csv("fram1.csv");
head(ds);


### Charger les modules necessaires
require(MCMCpack);


### Modelisation bayesienne par MCMC
moy.priori = rep(0, 7);
var.priori = rep(1e6, 7);
reglogist = MCMClogit(DIABETES ~ CURSMOKE + SEX + AGE + SYSBP + CURSMOKE*BMI,
                      data = ds, burnin = 1000, mcmc = 10000, thin = 10, 
                      b0 = moy.priori, B0 = 1/var.priori, seed=331133);
summary(reglogist);

## Graphiques de traces et de densite
par(mfrow = c(2,2));
plot(reglogist, auto.layout = FALSE);
autocorr.plot(reglogist, auto.layout = FALSE);


# les graphiques de trace commencent apres le burn-in.
# Sur les graphiques de trace, on ne constate aucune tendance particuliere.
# Le parametre de burn-in semble donc suffisant.

# Les graphiques d'auto-correlation n'incluent pas d'intervalles de confiance.
# On constate tout de meme que l'auto-correlation semble elevee.
# On devrait augmenter le nombre de thin et mcmc en consequence


### Modelisation bayesienne par MCMC - prise 2
moy.priori = rep(0, 7);
var.priori = rep(1e6, 7);
reglogist = MCMClogit(DIABETES ~ CURSMOKE + SEX + AGE + SYSBP + CURSMOKE*BMI,
                      data = ds, burnin = 1000, mcmc = 100000, thin = 100, 
                      b0 = moy.priori, B0 = 1/var.priori, seed=331133);
summary(reglogist);

## Graphiques de traces et de densite
par(mfrow = c(2,2));
plot(reglogist, auto.layout = FALSE);
autocorr.plot(reglogist, auto.layout = FALSE);
# Semble beaucoup mieux !