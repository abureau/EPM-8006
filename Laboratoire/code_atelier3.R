#EPM-8006: Concepts avancés en modélisation statistique I
#Professeur: Alexandre Bureau
#Auxiliaire d'enseignement: Loïc Mangnier

#Code R pour le laboratoire 3 Régression logistique
#Objectifs:
#À la fin de cet atelier, l'étudiant sera:
#  -L'estimation et l'interprétation du modèle de régression logistique en R
#  -Valider les hypothèses sous-jacentes au modèle de régression logistique
#  -Analyse de la multicollinéarité et des valeurs extrêmes


############################################################################################
#Importation des données
chp04 = read.table("D:\\EPM-8006\\Laboratoires\\Regression-Logistique\\data\\chp04.txt", header=TRUE)
chp05 = read.table("D:\\EPM-8006\\Laboratoires\\Regression-Logistique\\data\\chp05.txt", header=TRUE)

str(chp05)

#Création de la variable réponse faible poids de l'enfant
chp05$Y = ifelse(chp05$PDS<=2500,1,0)
table(chp05$Y)

chp05$PREM[chp05$PREM>1] = 1
nrow(unique(chp05[,c("PDSM","PREM","HT")]))
nrow(chp05)
#109 profils uniques (modalités) pour 190 individus au total dans la banque de données
#Que conclure ?
#Ici une modalité réfère au nombre de combinaisons uniques entre les trois variables explicatives

#Ajuste le modèle de régression logistique
model = glm(Y ~ PDSM + PREM + HT, data=chp05, family=binomial(link="logit"))
summary(model)
#Interprétation du modèle

exp(-0.03853)#OR
exp(confint(model))#CI pour OR

#Multicollinéarité: 
#Rappel: Quel est le problème avec la multicollinéarité ?
#Variance Inflation Factor (VIF)
#VIF mesure à quel point une variable est reliée aux autres variables 

library(rms)
vif = vif(model)
vif

library(mctest)
imcdiag(model)

#Si l'on veut retrouver les résultats manuellement
summary(lm(PDSM~PREM+HT, chp05))
1/(1-0.06981)#Formule du vif
summary(lm(PREM~PDSM+HT, chp05))
1/(1-0.01545)
summary(lm(HT~PDSM+PREM, chp05))
1/(1-0.05618)

#Valider r carre ajuste: Pas de sources utilisant le R-carré ajusté. J'irai avec ce dernier dans 
#le cas de grande dimension
#Interprétation?
#Bonus: Méthodes pour traiter la multicollinéarité: LASSO, Ridge, etc...

#Validation graphique des hypothèses du modèles
plot(model,which=1:5)
#Alignement des plots de résidus/valeurs prédites suivant deux courbes 

#Statistique-C (Goodness-of-fit)
DescTools::Cstat(model)
#Interprétation

#Valeurs extrêmes: DFBETAS

dfb=dfbetas(model)
#Le changement dans la valeur du coefficient lorsque l'on retire l'individu
#Cela permet de trouver les valeurs extrêmes qui ont le plus de 'leverage'

plot(1:nrow(dfb),dfb[,"(Intercept)"])
abline(h=0)
plot(1:nrow(dfb),dfb[,"PDSM"])
abline(h=0)
plot(1:nrow(dfb),dfb[,"PREM"])
abline(h=0)
plot(1:nrow(dfb),dfb[,"HT"])
abline(h=0)

#Quelles sont les conclusions à la vue des graphiques ?


#Bonus: Séparation quasi-complète: Prédiction quasi-parfaite, faible taille d'échantillon
#Régression logistique de Firth

#Stratification du poids de la mère en 5 intervalles fermés à gauche ouverts à droite
chp05$PDM = cut(chp05$PDSM,breaks=c(0,seq(45,75,by=10),200),right=FALSE)

chp05_compte = xtabs(~Y + PDM + PREM + HT,data=chp05)
#Interprétation 

chp05.2 = as.data.frame(chp05_compte)
#Fréquence de chaque modalité chez les cas et non-cas
#On passe alors d'une ligne par individu au format une ligne par modalité des variables explicatives

chp05.cas = chp05.2[chp05.2$Y==1,-1]
chp05.noncas = chp05.2[chp05.2$Y==0,-1]
names(chp05.noncas)[ncol(chp05.noncas)] = "Freqnc"

chp05.final = merge(chp05.cas,chp05.noncas)
chp05.final$PDMC = as.numeric(chp05.final$PDM)

nrow(unique(chp05[,c("PDM","PREM","HT")]))

evenements = cbind(chp05.final$Freq,chp05.final$Freqnc)
model2 = glm(evenements ~ chp05.final$PDMC + chp05.final$PREM + chp05.final$HT,family=binomial)
summary(model2)

par(mfrow=c(1,1))
plot(model2, which=1:5)
#Interprétation 

#Présence de surdispersion
library(aods3)
gof(model2)

dfb2=dfbetas(model2)

plot(1:nrow(dfb2),dfb2[,"(Intercept)"])
abline(h=0)
plot(1:nrow(dfb2),dfb2[,"chp05.final$PDMC"])
abline(h=0)
plot(1:nrow(dfb2),dfb2[,"chp05.final$PREM1"])
abline(h=0)
plot(1:nrow(dfb2),dfb2[,"chp05.final$HT1"])
abline(h=0)

