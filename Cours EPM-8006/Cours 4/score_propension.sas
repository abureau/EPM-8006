/**** Importation des donnees ****/
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/fram1.csv"
    OUT = fram1
    REPLACE
    DBMS = CSV;
RUN;

/* Estimation d'un modèle logistique du tabagisme et calcul de probabilité prédites */
proc logistic data=fram1 descending;
   model cursmoke = age bmi sex;
   output out=propension pred=prob;
run;

proc means data=propension;
var prob;
run;

proc sort data=propension;
by randid;
run;
/* Calcul du poids de chaque sujet (ajout d'une variable bidon pour que le merge répète la valeur de la moyenne) */

data propension;
  set propension;
  if cursmoke = 1 then w =1/prob;
  else w = 1/(1 - prob);
  bidon = 1;
run;

/* vérification de l'étendue des valeurs des poids*/
proc means data=propension;
  var w;
	OUTPUT OUT = ns MEAN = mipw;
run;

/* Normalisation du poids  */

data ns;
set ns;
bidon = 1;

data propension2;
merge propension ns;
by bidon;
nipw = w/mipw;
drop bidon;
run;

proc means data=propension2;
  var nipw;
run;
proc genmod data=propension2 descending;
  class randid;
  model diabetes = cursmoke / dist=bin;
  weight nipw;
  repeated subject=randid / type=ind printmle;
  estimate "tabagisme" cursmoke 1 /exp;
run;
