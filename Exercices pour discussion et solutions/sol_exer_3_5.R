#### Environnement de travail
setwd("C:\\Users\\denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


#### Charger les donnees
fram1 = read.csv("fram1.csv");


#3A - Estimation du modele de regression lineaire :

modA = lm(DIABP ~ SEX + CURSMOKE*AGE + BMI + I(BMI**2), data = fram1);
summary(modA);


#3B - Le test F du modele precedent donne la reponse. 
#     On peut aussi faire un test d'hypotheses simultanees

modA0 = lm(DIABP ~ 1, data = fram1);
anova(modA0, modA);

# On conclut qu'il existe une association entre les variables
# explicatives et la variable r√©ponse.

#3C

modC = lm(DIABP ~ SEX + AGE + BMI + I(BMI**2), data = fram1);
anova(modC, modA);


#3D

modD = lm(DIABP ~ SEX + CURSMOKE*AGE, data = fram1);
anova(modD, modA);

# On conclut qu'il existe une association entre l'IMC et la DBP.

#3E
$30^2 - 25^2 = 275$

L = matrix(c(0, 0, 0, 0, 5, 275, 0), nrow = 1, byrow = TRUE);
LB = coef(modA)%*%t(L);
se = sqrt(diag(L%*%vcov(modA)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), se, LL = t(LL), UL = t(UL), chisq, df = 1, pval);


# 3F

# La comparaison va dependre de l'age.
# En observant nos statistiques descriptives,
# on constate que la majorite des donnees sont comprises
# entre 40 et 60 ans. On va comparer le statut de fumeur a† 40, 50 et 60 ans.

L = matrix(c(0, 0, 1, 0, 0, 0, 40,
             0, 0, 1, 0, 0, 0, 50,
             0, 0, 1, 0, 0, 0, 60), nrow = 3, byrow = TRUE);
LB = coef(modA)%*%t(L);
se = sqrt(diag(L%*%vcov(modA)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), se, LL = t(LL), UL = t(UL), chisq, df = 1, pval);



# Pour les sujets de 40 ans, le fait de fumer est associe a une reduction
# de la DBP de 1.3 mmHg (IC ‡ 95%: -2.3 a -0.3 mmHg). Pour les sujets de 50 ans
# les donnees suggerent que le fait de fumer est associe a une reduction de la
# DBP, mais les donnees sont egalement compatibles avec une absence d'association
# (difference de -0.6 mmHg, IC ‡ 95%: -1.3 a 0.05 mmHg). Pour les sujets de 60 ans, les donnees
# sont peu informatives; des associations positives, negatives et nulles sont toutes compatibles
# avec les donnees (difference de 0.0 mmHg, IC ‡ 95%: -1.0 a 1.1 mmHg).
#
# Puisqu'il s'agit d'une etude observationnelle et que plusieurs variables potentiellement
# confondantes n'ont pas ete controlees dans le modele, les associations observees ne peuvent
# pas etre interpretees de facon causale.
