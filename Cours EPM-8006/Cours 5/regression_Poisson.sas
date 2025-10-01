data exm3_9;
 input E F A N @@;
ln=log(n);
cards;
 1 0 30 1500  0 0 45 3000   1 1 50 2000  0 1 64 4000
 ;

/* Diff�rence de taux */
PROC GENMOD;
MODEL A/N=E F / DIST=POISSON LINK=IDENTITY TYPE3;
RUN;

/* Rapport de taux */
PROC GENMOD;
MODEL A/N=E F / DIST=POISSON LINK=LOG TYPE3;
ESTIMATE "E" E 1;
ESTIMATE "taux de base" intercept 1;
output out=sortie predicted=pred resdev=rdev;
RUN;

proc print data=sortie;
run;

/* Rapport de taux (codage alternatif plus g�n�ralisable qui permet inf�rence exacte)*/
PROC GENMOD data=exm3_9;
MODEL A= E F / DIST=POISSON LINK=LOG OFFSET=LN TYPE3;
ESTIMATE "E" E 1;
EXACT "E" E / ESTIMATE=ODDS CLTYPE=MIDP;
OUTPUT OUT=taux  pred=p;
RUN;

data taux;
set taux;
taux = p/N;
run;

proc print;
run;
/* Notez que les tests de Wald de la diff�rence de taux et du rapport de taux 
   sont l�g�rement diff�rents, alors que le test du rapport de vraisemblance (Type 3)
   ne change pas */
