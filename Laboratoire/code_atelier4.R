#EPM-8006: Concepts avancés en modélisation statistique I
#Professeur: Alexandre Bureau
#Auxiliaire d'enseignement: Loïc Mangnier

#Code R pour le laboratoire 3 Régression logistique conditionnelle
#Objectifs:
#À la fin de cet atelier, l'étudiant sera:
#  - L'estimation et l'interprétation du modèle de régression logistique conditionnelle en R
#  - Discussion des biais en régression logistique conditionnelle


############################################################################################
library(survival)
#Importation des données
data = read.table("D:\\EPM-8006\\Laboratoires\\Regression-Logistique-Cond\\data\\exm08_04.txt", header=TRUE)
chp04 = read.table("D:\\EPM-8006\\Laboratoires\\Regression-Logistique-Cond\\data\\chp04.txt", header=TRUE)

str(data)
str(chp04)

data$membran = ifelse(data$MEMBRAN==1,1,0)
chp04$membran = ifelse(chp04$MEMBRAN==1,1,0)
chp04$prem = ifelse(chp04$PREM==1,1,0)
#L'appariement se fait sur l'âge de la mère: on conditionne donc sur l'âge pour retirer son effet


unique(data$AGE)

table(data$AGE, data$CAS)
#Quel type d'appariement ?

boxplot(AGE~CAS,data)
#Quelle interprétation donnée à ce boxplot?

model = clogit(CAS~membran+strata(AGE)+GEST, data=data, method = "exact", ties="exact")
summary(model)
car::Anova(model, type=3,test.statistic="Wald")
#Interprétation 

#On utilise un modèle de Cox car la vraisemblance de la régression logistique conditionnelle 
#peut s'écrire comme la vraisemblance du modèle de Cox sous certaines hypothèses

library(epiDisplay)
clogistic.display(model)


#Comparaison avec le modèle inconditionnel avec la variable AGE
model_incond = glm(CAS~membran+GEST+AGE, data=data, family=binomial())
summary(model_incond)

#Comparaison avec le modèle inconditionnel sans la variable AGE
model_incond = glm(CAS~membran+GEST+AGE, data=data, family=binomial())
summary(model_incond)

#Quelles conclusions ?

#Vérification des hypothèses du modèle conditionnel 

plot(data$GEST,residuals(model,type="deviance"))
abline(h=0)
lines(lowess(data$GEST,residuals(model,type="deviance")),col="red")
#Interprétation

#ou si stratification sur l'age + age gestationel

table(chp04$GEST, chp04$prem)
boxplot(GEST~prem,chp04)
boxplot(GEST~AGE,chp04)

sum(table(chp04$GEST, chp04$AGE)==1)
#88 individus qui vont être retirés de l'analyse 

colSums(table(chp04$GEST, chp04$AGE)==1)
rowSums(table(chp04$GEST, chp04$AGE)==1)

nrow(chp04)
unique(chp04[,c("GEST", "AGE")])
#Interprétation: Sens du biais attendu si les femmes les plus à risques sont les
#femmes jeunes et les plus agees et celles qui ont des ages gestationels faibles ?

model2 = clogit(prem~membran+strata(AGE)+strata(GEST), data=chp04,method = "exact", ties="exact")
summary(model2)

#Modèle inconditionnel
modstd = glm(prem~membran+AGE+GEST,data=chp04,family=binomial)
summary(modstd)
exp(coef(modstd))

#Différence entre l'approche conditionnelle et l'approche inconditionnelle

#Effet modifiant = interaction 
#Que se passe t-il si ma strate est un effet modifiant ?