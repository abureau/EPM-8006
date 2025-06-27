libname modeli " C:\Users\etudiant\Documents\EPM-8006\donnees";

DATA EXM; SET modeli.CHP05;

IF PREM=0 THEN PREM=0; ELSE PREM=1;

IF PDS=<2000 THEN Y=1;
IF 2000<PDS=<2500 THEN Y=2;
IF PDS>2500 THEN Y=3;

proc logistic;
model y=fume prem/link = glogit aggregate scale=none;
run;

/* Calcul de score de propension pour la scolarité

## Définition de la variable réponse dichotomique */
DATA EXM; SET modeli.CHP05;
IF PDS=<2500 THEN Y=1;
else Y=2;
run;

/* Modèle de prédiction de la scolarité */
PROC LOGISTIC DATA = exm;
MODEL scol = fume age pdsm / LINK = GLOGIT;
OUTPUT OUT = sortie P = pred;
RUN;

DATA poids;
SET sortie;
IF scol NE _LEVEL_ THEN DELETE;
w = 1/pred;
RUN;

PROC genmod DATA = poids;
class scol(ref='3') id / param=ref;
MODEL y = scol / dist=bin;
weight w;
  repeated subject=id / type=ind printmle;
  estimate "non-diplômé" scol 0 1 /exp;
  estimate "secondaire" scol 1 0 /exp;
RUN;
