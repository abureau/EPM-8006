libname modeli " C:\Users\etudiant\Documents\EPM-8006\donnees";

data pol; set modeli.chp04;
if prem = 2 then prem01 = 0; else prem01 = 1;
/* La variable PARIT est ramenée à trois catégories: 0, 1, 2&+. 
   Deux variables indicatrices sont utilisées: PAR0, PAR1 */
if parit=0 then par0=1; else par0=0;
if parit=1 then par1=1; else par1=0;
run;

/* Estimation d'un modèle logistique du transfert */
proc logistic data=pol descending;
   model transf = age gest par0 par1 gemel;
   output out=PRED pred=prob reschi=rchi resdev=rdev;
run;

/* Relation entre le transfert et les variables continues 

Approche par les résidus */
proc sgplot data=pred;
	SCATTER X = age Y = rdev /;
	LOESS X = age Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

proc sgplot data=pred;
	SCATTER X = gest Y = rdev /;
	LOESS X = gest Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

/* La relation de la log-cote de transfert avec l'âge est approximativement linéaire. On garde l'âge tel quel.

Dans la relation de la log-cote de transfert avec l'âge gestationnel on détecte un changement de pente
à environ 32 semaines. On définit une spline linéaire avec une variable de changement de pente après 32 semaines.
Une alternative serait de recoder l'âge gestationnel en tranches d'âge. */

data pol;
  set pol;
  if gest>32 then gest32 = gest - 32; else gest32 = 0;
run;

/* Estimation d'un modèle logistique du transfert avec spline linéaire pour l'âge gestationnel*/
proc logistic data=pol descending PLOT(ONLY) = ROC;
   model transf = age gest gest32 par0 par1 gemel /  ctable;
   output out=propension pred=prob reschi=rchi resdev=rdev;
run;
/* La meilleure spécificité possible à une sensibilité de 90% est 20.2% */

/* On examine les résidus pour vérifier la linéarité après recodage de
   l'âge gestationnel. Il n'y a plus d'écart flagrant de la linéarité. */
proc sgplot data=propension;
	SCATTER X = age Y = rdev /;
	LOESS X = age Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

proc sgplot data=propension;
	SCATTER X = gest Y = rdev /;
	LOESS X = gest Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;
/* Calcul de la probabilité de chaque sujet */

data propension;
  set propension;
  if transf = 2 then psuj = prob;
  else psuj = 1 - prob;
run;

proc sort data=propension;
  by transf;
run;

/* Vérification de l'étendue des valeurs des probabilités.
Pas de probabilité proche de 0 ou proche de 1 qui causeraient des problèmes.*/
proc means data=propension;
  var psuj;
run;

/* Inverse de la probabilité */
data propension;
  set propension;
  ipw = 1/psuj;
run;

/* vérification de l'étendue des valeurs des poids*/
proc means data=propension;
  var ipw;
run;

/* Comparaison des moyennes des covariables après pondération des sujets */
proc means data=propension;
  var age gest parit gemel;
  weight ipw;
  by transf;
run;
/* On observe que les moyennes des covariables sont presqu'égales 
chez les femmes transférées et non-transférées après pondération. */


/* Estimation du rapport de cote marginal de naissance prématurée 
Attention! Avec le lien logit, la colonne "Estimation de la moyenne" de la sortie de 
l'énoncé estimate ne donne pas l'exponentiel du coefficient. Il faut le demander avec
l'option exp et il apparaîtra dans la colonne "Valeur estimées de L'Bêta".
*/
proc genmod data=propension descending;
  class idn;
  model prem01 = transf / dist=bin;
  weight ipw;
  repeated subject=idn / type=ind printmle;
  estimate "transf" transf 1 /exp;
run;
