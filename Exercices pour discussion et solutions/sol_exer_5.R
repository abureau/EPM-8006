### Repertoire de travail
setwd("C:\\Users\\Denis Talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


### Importation des donnees
osteo = read.csv("osteo5.csv", na.strings=".")


### Charger les modules necessaires
require(mice);
require(geepack);
require(rms);


### Imputation multiple
# J'utilise l'imputation MICE etant donne que mes variables sont de differents types;

# Pour utiliser la regression logistique dans la fonction *mice* il faut que la variable a imputer soit
# de type *factor*. 

osteo$OSQ010A = factor(osteo$OSQ010A, levels = 2:1);
osteo$OSQ170 = factor(osteo$OSQ170, levels = 2:1);
osteo$OSQ200= factor(osteo$OSQ200, levels = 2:1);
osteo$RIAGENDR = factor(osteo$RIAGENDR, levels = 2:1);
osteo$RIDRETH1 = factor(osteo$RIDRETH1);
osteo$ALQ101 = factor(osteo$ALQ101, levels = 2:1);
osteo$OSQ130 = factor(osteo$OSQ130, levels = 2:1);

osteo2 = osteo[,c("OSQ130","OSQ170","OSQ200","RIAGENDR","RIDRETH1","RIDAGEYR","BMXBMI","ALQ101","OSQ010A")];
# Note : Je ne garde pas l'identifiant cette fois, parce que je prevois utiliser une regression logistique

mean(apply(osteo2, 1, anyNA)); # 19 % des observations sont incompletes

impexer5 = mice(data = osteo2, m = 20,
                method = c("logreg", "logreg", "logreg", "logreg", "polyreg", 
                           "pmm", "pmm", "logreg", "logreg"), seed = 1961759);


### Analyse des jeux de donnees imputes
osteo.exer5.multi = with(impexer5,
                         exp = glm(OSQ010A ~ ALQ101 + OSQ130 + OSQ170 + OSQ200 + BMXBMI +
                                             RIAGENDR + RIDAGEYR + RIDRETH1,
                                   family = "binomial"));
osteo.exer5 = pool(osteo.exer5.multi);
osteo.exer5.resume = summary(osteo.exer5);
RC = signif(exp(cbind(osteo.exer5.resume$estimate,
                      osteo.exer5.resume$estimate - 1.96*osteo.exer5.resume$std.error,
                      osteo.exer5.resume$estimate + 1.96*osteo.exer5.resume$std.error)), 3);
RC
# RC = 0.66
# IC = (0.37, 1.17);
# La consommation d'alcool est associee a une reduction importante du
# risque de fracture de la hance, mais les donnees sont compatibles
# avec des associations allant de fortement protectrices a moderement
# deleteres. La nature transversale des donnees et
# le risque de confusion residuelle empeche d'interpreter causalement
# cette association. Par ailleurs, une consommation de 12 boissons
# alcoolisees au cours d'une annee n'est pas une consommation extreme.
# Il est donc possible que des consommations moderees avec un effet
# neutre soient combinees avec des consommations elevees
# ayant un effet negatif dans la variable d'exposition utilisee.

