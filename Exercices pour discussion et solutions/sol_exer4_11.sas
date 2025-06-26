data exm3_9;
 input R Y N @@;
ln=log(n);
cards;
 1 480 59314  0 604 83879  
 ;

/* Rapport de taux */
PROC GENMOD;
MODEL Y/N=R / DIST=POISSON LINK=LOG TYPE3;
ESTIMATE "R�gion" R 1;
ESTIMATE "taux de base" intercept 1;
RUN;

/* Rapport de taux (codage alternatif plus g�n�ralisable qui permet inf�rence exacte)*/
PROC GENMOD;
MODEL Y= R / DIST=POISSON LINK=LOG OFFSET=LN TYPE3;
ESTIMATE "R�gion" R 1;
EXACT "R�gio" R / ESTIMATE=ODDS CLTYPE=MIDP;
RUN;

/* Notez que les tests de Wald de la diff�rence de taux et du rapport de taux 
   sont l�g�rement diff�rents, alors que le test du rapport de vraisemblance (Type 3)
   ne change pas */
