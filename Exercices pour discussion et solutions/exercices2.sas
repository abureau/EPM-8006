libname modeli " C:\Users\etudiant\Documents\EPM-8006\donnees";

data pol; set modeli.chp04;
if prem = 2 then prem01 = 0; else prem01 = 1;
/* La variable PARIT est ramen�e � trois cat�gories: 0, 1, 2&+. 
   Deux variables indicatrices sont utilis�es: PAR0, PAR1 */
if parit=0 then par0=1; else par0=0;
if parit=1 then par1=1; else par1=0;
run;

/* Estimation d'un mod�le logistique du transfert */
proc logistic data=pol descending;
   model transf = age gest par0 par1 gemel;
   output out=PRED pred=prob reschi=rchi resdev=rdev;
run;

/* Relation entre le transfert et les variables continues 

Approche par les r�sidus */
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

/* La relation de la log-cote de transfert avec l'�ge est approximativement lin�aire. On garde l'�ge tel quel.

Dans la relation de la log-cote de transfert avec l'�ge gestationnel on d�tecte un changement de pente
� environ 32 semaines. On d�finit une spline lin�aire avec une variable de changement de pente apr�s 32 semaines.
Une alternative serait de recoder l'�ge gestationnel en tranches d'�ge. */

data pol;
  set pol;
  if gest>32 then gest32 = gest - 32; else gest32 = 0;
run;

/* Estimation d'un mod�le logistique du transfert avec spline lin�aire pour l'�ge gestationnel*/
proc logistic data=pol descending PLOT(ONLY) = ROC;
   model transf = age gest gest32 par0 par1 gemel /  ctable;
   output out=propension pred=prob reschi=rchi resdev=rdev;
run;
/* La meilleure sp�cificit� possible � une sensibilit� de 90% est 20.2% */

/* On examine les r�sidus pour v�rifier la lin�arit� apr�s recodage de
   l'�ge gestationnel. Il n'y a plus d'�cart flagrant de la lin�arit�. */
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
/* Calcul de la probabilit� de chaque sujet */

data propension;
  set propension;
  if transf = 2 then psuj = prob;
  else psuj = 1 - prob;
run;

proc sort data=propension;
  by transf;
run;

/* V�rification de l'�tendue des valeurs des probabilit�s.
Pas de probabilit� proche de 0 ou proche de 1 qui causeraient des probl�mes.*/
proc means data=propension;
  var psuj;
run;

/* Inverse de la probabilit� */
data propension;
  set propension;
  ipw = 1/psuj;
run;

/* v�rification de l'�tendue des valeurs des poids*/
proc means data=propension;
  var ipw;
run;

/* Comparaison des moyennes des covariables apr�s pond�ration des sujets */
proc means data=propension;
  var age gest parit gemel;
  weight ipw;
  by transf;
run;
/* On observe que les moyennes des covariables sont presqu'�gales 
chez les femmes transf�r�es et non-transf�r�es apr�s pond�ration. */


/* Estimation du rapport de cote marginal de naissance pr�matur�e 
Attention! Avec le lien logit, la colonne "Estimation de la moyenne" de la sortie de 
l'�nonc� estimate ne donne pas l'exponentiel du coefficient. Il faut le demander avec
l'option exp et il appara�tra dans la colonne "Valeur estim�es de L'B�ta".
*/
proc genmod data=propension descending;
  class idn;
  model prem01 = transf / dist=bin;
  weight ipw;
  repeated subject=idn / type=ind printmle;
  estimate "transf" transf 1 /exp;
run;
