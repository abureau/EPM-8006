#########################
# Solution exercice 4.5 #
#########################


#### Environnement de travail
setwd("C:\\Users\\denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


#### Charger les modules necessaires
require(multcomp);


#### Charger les donnees
fram1 = read.csv("fram1.csv");
summary(fram1);
names(fram1);


#### A)
fit = glm(DIABETES ~ CURSMOKE + SEX + AGE + SYSBP + BMI + CURSMOKE*BMI,
          data = fram1,
          family = "binomial");

#### B);
fitr = glm(DIABETES ~ SEX + AGE + SYSBP + BMI,
          data = fram1,
          family = "binomial");
anova(fit, fitr, test = "Chi");

#### C)
fum_nfum_IMC25 = glht(fit, linfct = "CURSMOKE + 25*CURSMOKE:BMI=0");
summary(fum_nfum_IMC25);
exp(confint(fum_nfum_IMC25)$confint);
# RC ~ RR = 0.69 (IC a 95%: 0.44 a 1.09)
# RC ~ RR parce que la reponse est rare




#########################
# Solution exercice 4.6 #
#########################


#### Environnement de travail
setwd("C:\\Users\\denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


#### Charger les modules necessaires
require(rms);
require(geepack);


#### Charger les donnees
fram12 = read.csv("fram12.csv");
summary(fram12);
names(fram12);


#### Creation des variables HTA
fram12$HTA1 = with(fram12, (SYSBP1 > 140) | (DIABP1 > 90) | (BPMEDS1 == 1))*1;
fram12$HTA2 = with(fram12, (SYSBP2 > 140) | (DIABP2 > 90) | (BPMEDS2 == 1))*1;
summary(fram12);


#### Statistiques descriptives
# ...


#### Strategie de modelisation
# - Je choisis un modele log-lineaire semiparametrique
#   (Poisson robuste).
# - Je vais modeliser les variables confondantes continues
#   a l'aide de splines cubiques.*/

fit = geeglm(HTA2 ~ CURSMOKE2 + rcs(AGE1) + SEX + HTA1 + 
                    rcs(BMI1) + factor(educ1) + PREVCHD1,
             data = fram12,
             family = poisson(link = "log"), id = RANDID); 

#### Verification des hypotheses

## 1. Absence de relation residuelle
## Aucune variable continue sans splines - non applicable


## 2. Independance 
## Ok selon nos informations


## 3. Multicollinearite
vif(fit); # VIF de CURSMOKE2 < 10 = ok

## 4. Donnees influentes
fit.glm = glm(HTA2 ~ CURSMOKE2 + rcs(AGE1) + SEX + HTA1 + 
                     rcs(BMI1) + factor(educ1) + PREVCHD1,
             data = fram12,
             family = "binomial"); 
dfbs = dfbetas(fit.glm);
summary(dfbs); # 2e colone = CURSMOKE1
round(summary(dfbs[,2]), 2); # ok 


## 5. Separation
# Pas de message d'erreur ou d'avertissement

sum.fit = summary(fit);
round(data.frame(RR = exp(sum.fit$coef[-1,1]),
                 LL = exp(sum.fit$coef[-1,1] - 1.96*sum.fit$coef[-1,2]),
                 UL = exp(sum.fit$coef[-1,1] + 1.96*sum.fit$coef[-1,2])), 2);
# Les IC semblent corrects


# 6. Sur-dispersion
# Au moins une variable explicative continue = non applicable


#### Interpretation
round(data.frame(RR = exp(sum.fit$coef[2,1]),
                 LL = exp(sum.fit$coef[2,1] - 1.96*sum.fit$coef[2,2]),
                 UL = exp(sum.fit$coef[2,1] + 1.96*sum.fit$coef[2,2])), 2);

/* RR = 1.02 (IC a 95%: 0.94 a 1.10).
Le tabagisme n'est pas associe a la prevalence
d'hypertension 6 ans plus tard et les donnees
sont compatibles avec des associations
allant de legerement protectrices a legerement nefastes. */




#########################
# Solution exercice 4.7 #
#########################


#### Environnement de travail
setwd("C:\\Users\\denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


#### Charger les modules necessaires
require(rms);
require(geepack);
require(tableone);
require(survey);


#### Charger les donnees
fram12 = read.csv("fram12.csv");
summary(fram12);
names(fram12);



#### Creation des variables HTA
fram12$HTA1 = with(fram12, (SYSBP1 > 140) | (DIABP1 > 90) | (BPMEDS1 == 1))*1;
fram12$HTA2 = with(fram12, (SYSBP2 > 140) | (DIABP2 > 90) | (BPMEDS2 == 1))*1;
summary(fram12);


#### Statistiques descriptives
# ...

#### Strategie de modelisation
# - On modelise l'exposition cette fois
# - Je vais modeliser les variables confondantes continues
#   a l'aide de splines cubiques.


#### Modele pour l'exposition
fitX = glm(CURSMOKE2 ~ rcs(AGE1) + SEX + HTA1 + rcs(BMI1) + factor(educ1) + PREVCHD1,
           family = "binomial",
           data = fram12);


#### Verification des hypotheses 

## Positivite empirique :
summary(fitX$fitted); # min = 0.06, max = 0.81, ok


## 1. Absence de relation residuelle
# Aucune variable continue sans splines - non applicable


## 2. Independance
# Ok selon nos informations


## 3. Multicollinearite
vif(fitX); # Plusieurs vifs eleves, mais en raison des splines,
           # je ne suis donc pas inquiet


## 4. Donnees influentes - comme si predictif
plot(y = cooks.distance(fitX), x = fram12$RANDID);
# Aucune observation particulierement influente ne se demarque


## 5. Separation
# Pas de message d'erreur ou d'avertissement, les
# IC sont corrects (ceux de certains termes splines seraient larges)


## 6. Sur-dispersion
# Au moins une variable explicative continue = non applicable



#### Calcul des poids
fram12$w = with(fram12, CURSMOKE2/fitX$fitted + (1 - CURSMOKE2)/(1 - fitX$fitted));


#### Verification de l'equilibre

w.ds = svydesign(id=~1, weights = fram12$w, data = fram12);
print(svyCreateTableOne(vars = c("AGE1", "SEX", "HTA1",
                                 "BMI1", "educ1", "PREVCHD1"),
                        strata = "CURSMOKE2",
                        factorVars = c("SEX", "HTA1", "PREVCHD1", "educ1"),
                        data = w.ds), test = FALSE, smd = TRUE);
# Toutes les moyennes et tous les ecarts-types sont maintenant bien equilibrees



#### Ajustement du modele pondere
fit.RR = geeglm(HTA2 ~ CURSMOKE2, data = fram12, weights = w,
                id = RANDID, family = binomial(link = "log"));
summary(fit.RR);
data.frame(est = exp(summary(fit.RR)$coef[2,1]),
           LL = exp(summary(fit.RR)$coef[2,1] - 1.96*summary(fit.RR)$coef[2,2]),
           UL = exp(summary(fit.RR)$coef[2,1] + 1.96*summary(fit.RR)$coef[2,2]));
# RR = 1.02 IC a 95%: 0.93 a 1.12
# Donnees sont compatibles avec des associations allant de legerement protectrices
# a legerement deleteres.





#########################
# Solution exercice 4.8 #
#########################

#### Environnement de travail
setwd("C:\\Users\\denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


#### Charger les modules necessaires
require(rms);
require(pROC); # Pour calculer les auc


#### Charger les donnees
fram12 = read.csv("fram12.csv");
summary(fram12);
names(fram12);


#### Creation des bases entrainement et validation
set.seed(4791491);
ds = fram12[fram12$DIABETES1 == 0,];
rand = sample(1:nrow(ds), size = nrow(ds)*2/3, replace = FALSE);
entrainement = ds[rand,];
validation = ds[-rand,];


#### Liste des variables
names(entrainement);

# Je choisis ces variables comme potentiellement pertinentes :
# - SEX
# - AGE1
# - educ1
# - GLUCOSE1
# - BMI1


#### Quelques statistiques descriptives
tapply(entrainement$AGE1, INDEX = entrainement$DIABETES2, summary);
tapply(entrainement$BMI1, INDEX = entrainement$DIABETES2, summary);
tapply(entrainement$GLUCOSE1, INDEX = entrainement$DIABETES2, summary);

prop.table(table(entrainement$DIABETES2, entrainement$SEX), 2);
prop.table(table(entrainement$DIABETES2, entrainement$educ1), 2);
# educ1 n'est probablement pas tres pertinent
# compte tenu du nombre de categories. */

# Notons qu'avec seulement 31 evenements, on ne devrait
# meme pas faire de selection basee sur les donnees.
# On est a fort risque de surajustement. 
# On le fait ici seulement a des fins pedagogiques. */

# Voici les trois modeles que je choisis de comparer :
# Modele 1: Les variables continues dichotomisees
# Modele 2: Les variables continues entrees comme lineaires
# Modele 3: Les variables continues entrees en splines cubiques


# Je code en sachant qu'il n'y a pas de donnees manquantes
entrainement$AGE45 = 1*(entrainement$AGE1 > 45);
entrainement$surpoids = 1*(entrainement$BMI1 > 25);
entrainement$prediabete = 1*(entrainement$GLUCOSE1 > 100);


## Modele 1 - Variables dichotomisees
fit1 = glm(DIABETES2 ~ SEX + AGE45 + surpoids + prediabete,
           data = entrainement, family = "binomial");
auc(entrainement$DIABETES2, predict(fit1, type = "response"));
# 0.7116


## Modele 2 - Variables lineaires
fit2 = glm(DIABETES2 ~ SEX + AGE1 + BMI1 + GLUCOSE1,
           data = entrainement, family = "binomial");
auc(entrainement$DIABETES2, predict(fit2, type = "response"));
# 0.8096


## Modele 3 - Variables splines
fit3 = glm(DIABETES2 ~ SEX + rcs(AGE1) + rcs(BMI1) + rcs(GLUCOSE1),
           data = entrainement, family = "binomial");
auc(entrainement$DIABETES2, predict(fit3, type = "response"));
# 0.8178
summary(fit3); # On a une indication de problemes de separation avec les erreurs-types tres grands


# Je choisis le modele avec  variables continues


#### Verification des hypotheses

#### Verification des hypotheses
resid = resid(fit2, "pearson");

# 1. Absence de relation residuelle
plot(y = resid, x = entrainement$AGE1, pch = 16);
lines(lowess(y = resid, x = entrainement$AGE1), lwd = 4, col = "brown");
abline(h = 0, lwd = 4, col = "purple");

plot(y = resid, x = entrainement$BMI1, pch = 16);
lines(lowess(y = resid, x = entrainement$BMI1), lwd = 4, col = "brown");
abline(h = 0, lwd = 4, col = "purple");

plot(y = resid, x = entrainement$GLUCOSE1, pch = 16);
lines(lowess(y = resid, x = entrainement$GLUCOSE1), lwd = 4, col = "brown");
abline(h = 0, lwd = 4, col = "purple");

# Ca semble relativement ok, bien que certaines deviations dans les extremes


# 2. Independence - ok selon le contexte


# 3. Collineariteà
vif(fit2); # ok


# 4. Donnees influentes ou extremes
plot(y = cooks.distance(fit2), x = entrainement$RANDID);
# Semble relativement ok

# 5. Absence de separation
#    Aucun message d'avertissement ou d'IC incroyablement larges


# 6. Surdispersion
# Non applicable comme au moins une variable continue


#### Validation
pred = predict(fit2, newdata = validation, type = "response");
auc(validation$DIABETES2, pred);
# auc = 0.8404

fit.val = glm(DIABETES2 ~ log(pred/(1 - pred)), data = validation, family = "binomial");
summary(fit.val);
confint(fit.val);
# Le modele semble plutot bien calibre. L'IC pour l'ordonnee a l'origine couvre 0
# et celui pour la pent couvre 1.

# En somme, considerant le peu d'evenements disponibles,
# nous sommes quand meme parvenus a creer un bon modele.
# Par contre, la mesure du glucose demande une prise de
# sang a jeun. Ce n'est donc pas un outil tres simple
# a utiliser





