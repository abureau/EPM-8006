/* Illustration de transformation spline */
libname modeli " C:\Users\etudiant\Documents\EPM-8006\donnees";

DATA POL; SET modeli.CHP05;

/* Définition de la variable réponse de faible poids de naissance (< 2500g) */
IF PDS<=2500      THEN Y=1;     ELSE Y=2;

/* recodage de la variable de prématurité en 2 catégories oui/non */
IF PREM IN(1,2,3) THEN PREM=1;  ELSE PREM=0;
/* recodage du poids de la mère en une variable codant des intervalles de 10 kg de 1 à 5 */
if      pdsm<45 then pdm=1;
if  45<=pdsm<55 then pdm=2;
if  55<=pdsm<65 then pdm=3;
if  65<=pdsm<75 then pdm=4;
if     pdsm>=75 then pdm=5;
run;

/* Modèle du faible poids de naissance en fonction du poids de la mère, de l'antécédant
   de prématurité aux grossesses antérieures et de l'hypertension chez la mère pendant la grossesse. */

PROC TRANSREG DATA = pol DESIGN;
    MODEL BSPLINE(age);
    OUTPUT OUT = sp_age;
    ID ID;
RUN;

data pol2;
merge pol sp_age;
by id;
run;

proc logistic data=pol2;
model y = age_1-age_3;
output out = sortie xbeta=xb;
run;

proc sgplot data=sortie;
  scatter x=AGE y=xb;
run;
