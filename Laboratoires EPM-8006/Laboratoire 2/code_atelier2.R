#EPM-8006: Concepts avancés en modélisation statistique I
#Professeur: Alexandre Bureau
#Auxiliaire d'enseignement: Loïc Mangnier

#Code R pour le laboratoire 2 Régression multiple, combinaison linéaire et taille d'échantillon
#Objectifs:
#À la fin de cet atelier, l'étudiant sera:
#  -L'estimation et l'interprétation du modèle de régression linéaire multiple en R
#  -Valider les hypothèses sous-jacentes au modèle de régression linéaire multiple
#  -Faire des tests d'hypothèses multiples et combinaisons linéaires
#  - Calcul de la corrélation partielle + taille d'échantillon nécessaire


############################################################################################
#Importation des données
fram1 = read.csv2("D:\\EPM-8006\\Laboratoires\\Regression-Multiple-Puissance\\data\\fram1.csv", header=TRUE, sep=",")

#Validation des données
str(fram1)

fram1$SYSBP = as.numeric(fram1$SYSBP)
fram1$DIABP = as.numeric(fram1$DIABP)
fram1$BMI = as.numeric(fram1$BMI)

#Création de la variable BMI2
fram1$BMI2 = fram1$BMI^2

#Régression linéaire multiple de la pression artérielle diastolique 
modelA = lm(DIABP~SEX+CURSMOKE*AGE+BMI+BMI2, data=fram1)
summary(modelA)

#Validation graphique des hypothèses du modèle
plot(modelA)
#Hétéroscédasticité
#Normalité des résidus

#Test d'hypothèses simultanées
#Est-ce qu'au moins une variable est significativement associée avec la pression diastolique ?

#Modèle nulle (seulement une ordonnée à l'origine)
modelA_nul = lm(DIABP~1, data=fram1)
anova(modelA_nul,modelA)

#Modèle sans l'effet du statut de fumeur
model_A_sansfum = lm(DIABP~SEX+AGE+BMI+BMI2, data=fram1)
anova(model_A_sansfum, modelA)

#Modèle sans l'effet de l'IMC
model_A_sansBMI = lm(DIABP~SEX+CURSMOKE*AGE,data=fram1)
anova(model_A_sansBMI,modelA)

#Test sur les combinaisons linéaires:

#Test d'hypothèse multiple pour connaitre la différence de pression diastolique moyenne 
#d'un individu d'IMC de 25 et un individu d'IMC de 30
#1ere étape: écrire le modèle pour un individu avec un IMC de 30 (les autres variables gardées fixes)
#2eme étape: écrire le modèle pour un individu avec un IMC de 25 (les autres variables gardées fixes)
#Faire la différence des deux modèles
summary(multcomp::glht(modelA, matrix(c(0,0,0,0,5,275,0), 1)))

#Si l'on veut refaire la procédure à la main
L = matrix(c(0,0,0,0,5,275,0), 1)


LB = coef(modelA)%*%t(L)
#La différence de pression diastolique pour un individu d'IMC de 30 et un individu d'IMC de 25, toutes choses restant
#égales par ailleurs

se = sqrt(diag(L%*%vcov(modelA)%*%t(L)))
#L'erreur standard en tenant compte du contraste

LL = LB - 1.96*se 
#Borne inférieure de l'intervalle de confiance à 95%

UL = LB + 1.96*se
#Borne supérieure de l'intervalle de confiance à 95%

chisq = (t(LB)/se)**2
#Statistique de test, égale au carré de la statistique de student fournie par multcomp::glht

pval = pchisq(chisq, df = 1, lower.tail = FALSE)
#Valeur-p 

data.frame(estimate = t(LB), se, LL = t(LL), UL = t(UL), chisq, df = 1, pval)
#Équivalent à la sortie de multcomp::glht

#ou
summary(multcomp::glht(modelA, "5*BMI + 275*BMI2=0"))

#Test d'hypothèse multiple pour connaitre la différence de pression diastolique moyenne 
#d'un individu fumeur âgé de 40, 50 et 60 ans
summary(multcomp::glht(modelA, matrix(c(0,0,1,0,0,0,40,
                                        0,0,1,0,0,0,50,
                                        0,0,1,0,0,0,60), 3, byrow = TRUE)))
#ou
summary(multcomp::glht(modelA,c("CURSMOKE + 40*CURSMOKE:AGE = 0", "CURSMOKE + 50*CURSMOKE:AGE = 0","CURSMOKE + 60*CURSMOKE:AGE = 0")))

#Interprétation des deux modèles précédents
confint(multcomp::glht(modelA, "5*BMI + 275*BMI2=0"))

confint(multcomp::glht(modelA, matrix(c(0,0,1,0,0,0,40,
                                        0,0,1,0,0,0,50,
                                        0,0,1,0,0,0,60), 3, byrow = TRUE)))

#Questions supplémentaires:
#Définitions de la valeur-p + intervalles de confiances
#Pourquoi on ajuste pour la multiplicité ?

##########################################################
#Calcul de la taille d'échantillon pour la régression linéaire
fram12 = read.csv2("D:\\EPM-8006\\Laboratoires\\Regression-Multiple-Puissance\\data\\fram12.csv", header=TRUE, sep=",")

fram12$SYSBP1 = as.numeric(fram12$SYSBP1)
fram12$DIABP1 = as.numeric(fram12$DIABP1)
fram12$BMI1   = as.numeric(fram12$BMI1)
fram12$SYSBP2 = as.numeric(fram12$SYSBP2)
fram12$BMI2   = as.numeric(fram12$BMI2)
fram12$DIABP2 = as.numeric(fram12$DIABP2)

#Corrélation partielle
mod = lm(SYSBP2~CURSMOKE2+SYSBP1 + AGE1 + SEX + CURSMOKE1,data=fram12)
sqrt(sensemakr::partial_r2(mod, covariates="CURSMOKE2"))

#Taille d'échantillon requise pour avoir une puissance de 80% et un effet de 0.01
powerMediation::ss.SLR.rho(power=0.8,rho=0.01^2)

#Questions supplémentaires:
#Quelle est la corrélation partielle du Sexe ?
#Quelle est la taille d'échantillon requise à un niveau de puissance de 80% pour l'effet obsevé du Sexe ?

