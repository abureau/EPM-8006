/* Illustration de graphiques diagnostiques */
libname modeli "/workspaces/workspace/Données EPM-8006/donnees";

DATA POL; SET modeli.CHP05;

/* D�finition de la variable r�ponse de faible poids de naissance (< 2500g) */
IF PDS<=2500      THEN Y=1;     ELSE Y=2;

/* recodage de la variable de pr�maturit� en 2 cat�gories oui/non */
IF PREM IN(1,2,3) THEN PREM=1;  ELSE PREM=0;
/* recodage du poids de la m�re en une variable codant des intervalles de 10 kg de 1 � 5 */
if      pdsm<45 then pdm=1;
if  45<=pdsm<55 then pdm=2;
if  55<=pdsm<65 then pdm=3;
if  65<=pdsm<75 then pdm=4;
if     pdsm>=75 then pdm=5;
run;

/* Mod�le du faible poids de naissance en fonction du poids de la m�re, de l'ant�c�dant
   de pr�maturit� aux grossesses ant�rieures et de l'hypertension chez la m�re pendant la grossesse. */

/* Analyse des sujets individuellement. Approche qui donne un r�sidu par sujet.
 
Comme la variable PDSM est quantitative et a beaucoup de valeurs distinctes, il y a
presqu'autant de modalit�s que d'observations, et on ne peut pas faire mieux.*/

ods html;
ods graphics on;

/* Estimation du mod�le */

PROC LOGISTIC data=pol;
 MODEL Y= PDSM PREM HT / aggregate=(PDSM PREM HT) scale=none influence iplots;
 OUTPUT OUT=PRED pred=prob xbeta=xb reschi=rchi resdev=rdev h=hm dfbetas=_all_ c=dc;
RUN;

proc contents; run;

/* Graphiques de diagnostics. */

proc sgplot data=pred;
	SCATTER X = xb Y = rdev / group=Y;
	LOESS X = xb Y = rdev / smooth=0.5;
	REFLINE 0;
RUN;

/* R�sidu de Pearson en fonction de la diagonale de la matrice de projection (levier)
   comme dans R */
proc gplot data=pred;
  plot rchi*hm=Y;
run;

proc gplot data=pred;
  plot rdev*prob=Y;
  plot hm*prob=Y;
  plot ddev*prob=Y;
  plot dfbeta_pdsm*prob=Y;
  plot dfbeta_prem*prob=Y;
  plot dfbeta_ht*prob=Y;
  plot dc*prob=Y;
run;

proc gplot data=pred;
  plot rdev*xb=Y;
  plot hm*xb=Y;
  plot ddev*xb=Y;
  plot dfbeta_pdsm*xb=Y;
  plot dfbeta_prem*xb=Y;
  plot dfbeta_ht*xb=Y;
  plot dc*xb=Y;
run;

/* V�rification de la multicollin�arit� */

PROC reg data=pol;
 MODEL Y= PDSM PREM HT / vif;
RUN;

/* Stratifier le poids de la m�re 

Rempla�ons pdsm par une variable codant des intervalles de 10 kg de 1 � 5,
   en passant du format avec une ligne par sujet au format �v�nements/observations avec
   une ligne par modalit� */

/* On commence par cr�er un tableau des effectifs de chaque modalit� pour les cas
   et les non-cas */
proc freq data=pol;
  tables pdm*prem*ht*y / out=tableau;
run;
data compte_cas;
  set tableau;
  where y=1;
  rename count=n_cas;
run;

data compte_noncas;
  set tableau;
  where y=2;
  rename count=n_noncas;
run;

/* Enfin, on r�unit les deux tableaux de fa�on � avoir les effectifs des cas
   et des non-cas sur la m�me ligne pour chaque modalit� */
data chp5_compte_final;
  merge compte_cas compte_noncas;
  by pdm prem ht;
  if n_cas = . then n_cas = 0;
  if n_noncas = . then n_noncas = 0;
  n_total = n_cas+n_noncas;
run;

PROC LOGISTIC;
 MODEL n_cas/n_total= PDM PREM HT / aggregate=(pdm prem ht) scale=none influence iplots;
 OUTPUT OUT=PRED pred=prob xbeta=xb reschi=rchi resdev=rdev h=hm dfbetas=_all_ difdev=ddev difchisq = dchisq c=dc;
RUN;

proc sgplot data=pred;
	SCATTER X = xb Y = rdev /;
	LOESS X = xb Y = rdev / smooth=0.7;
	REFLINE 0;
RUN;

proc gplot data=pred;
  plot rdev*prob;
  plot hm*prob;
  plot ddev*prob;
  plot dfbeta_pdm*prob;
  plot dfbeta_prem*prob;
  plot dfbeta_ht*prob;
  plot dc*prob;
run;

/* Inspection des r�sidus de l'�ge */

/* Cas o� la relation entre le logit du risque et l'�ge est lin�aire */

/* Conversion du format avec une ligne par sujet au format �v�nements/observations avec
   une ligne par modalit� */

/* On commence par cr�er un tableau des effectifs de chaque modalit� pour les cas
   et les non-cas */
proc freq data=modeli.chp04;
  tables age*prem / out=tableau;
run;

/* On s�pare ensuite les lignes pour les cas des lignes pour les non-cas
   dans deux tableaux de donn�es distincts */
data compte_cas;
  set tableau;
  where prem=1;
  rename count=n_cas;
run;

data compte_noncas;
  set tableau;
  where prem=2;
  rename count=n_noncas;
run;

/* Enfin, on r�unit les deux tableaux de fa�on � avoir les effectifs des cas
   et des non-cas sur la m�me ligne pour chaque modalit� */
data chp4groupeage;
  merge compte_cas compte_noncas;
  by age;
  if n_cas = . then n_cas = 0;
  if n_noncas = . then n_noncas = 0;
  n_total = n_cas+n_noncas;
run;

/* Estimation du mod�le */

proc logistic data=chp4groupeage;
model n_cas/n_total = age / aggregate=(age) scale=none;
 OUTPUT OUT=PRED pred=prob reschi=rchi resdev=rdev h=hm dfbetas=_all_  c=dc;
run;

/* Graphiques de diagnostics. */

proc sgplot data=pred;
	SCATTER X = age Y = rdev /;
	LOESS X = age Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

proc gplot data=pred;
  plot rdev*age;
  plot rchi*age;
  plot dfbeta_age*age;
run;

* Approche alternative pour les r�sidus de Pearson;
* Commencer par faire l'analyse de la base de donn�es;
proc logistic data=modeli.chp04;
MODEL prem = AGE;
 OUTPUT OUT=PRED2 pred=prob reschi=rchi;
RUN;

proc sort data=pred2;
by age;

* Calcul de la somme des r�sidus de toutes les observations au m�me �ge;
proc means data=pred2;
by age;
var rchi;
output out=predniveau sum=rchisomme;
run;

* Division par la racine carr�e du nombre d'observations au m�me �ge;
data predniveau;
  set predniveau;
  rchi = rchisomme/sqrt(_freq_);
run;
proc gplot data=predniveau;
  plot rchi*age;
run;

/* R�gression log-binomiale */
proc genmod data=chp4groupeage;
model n_cas/n_total = age / dist=bin link=log aggregate=(age) noscale;
 OUTPUT OUT=PRED pred=prob reschi=rchi resdev=rdev dfbeta=_all_ cooksd=dc;
run;

proc sgplot data=pred;
	SCATTER X = age Y = rdev /;
	LOESS X = age Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

proc gplot data=pred;
  plot rdev*age;
  plot rchi*age;
  plot dfbeta2*age;
run;

/* Cas o� la relation entre le logit du risque et l'�ge n'est pas lin�aire */

/* Conversion du format avec une ligne par sujet au format �v�nements/observations avec
   une ligne par modalit� */

/* On commence par cr�er un tableau des effectifs de chaque modalit� pour les cas
   et les non-cas */
proc freq data=pol;
  tables age*y / out=tableau;
run;

/* On s�pare ensuite les lignes pour les cas des lignes pour les non-cas
   dans deux tableaux de donn�es distincts */
data compte_cas;
  set tableau;
  where y=1;
  rename count=n_cas;
run;

data compte_noncas;
  set tableau;
  where y=2;
  rename count=n_noncas;
run;

/* Enfin, on r�unit les deux tableaux de fa�on � avoir les effectifs des cas
   et des non-cas sur la m�me ligne pour chaque modalit� */
data chp5groupeage;
  merge compte_cas compte_noncas;
  by age;
  if n_cas = . then n_cas = 0;
  if n_noncas = . then n_noncas = 0;
  n_total = n_cas+n_noncas;
run;

proc logistic data=chp5groupeage;
model n_cas/n_total = age/ aggregate=(age) scale=none;
 OUTPUT OUT=PRED pred=prob reschi=rchi resdev=rdev h=hm dfbetas=_all_ c=dc;
run;

proc sgplot data=pred;
	SCATTER X = age Y = rdev /;
	LOESS X = age Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

proc gplot data=pred;
  plot rdev*age;
  plot rchi*age;
  plot dfbeta_age*age;
run;

/* R�gression log-binomiale */
proc genmod data=chp5groupeage;
model n_cas/n_total = age / dist=bin link=log aggregate=(age) noscale;
 OUTPUT OUT=PRED pred=prob reschi=rchi resdev=rdev dfbeta=_all_ cooksd=dc;
run;

proc sgplot data=pred;
	SCATTER X = age Y = rdev /;
	LOESS X = age Y = rdev / smooth=0.8;
	REFLINE 0;
RUN;

proc gplot data=pred;
  plot rdev*age;
  plot rchi*age;
  plot dfbeta2*age;
run;
