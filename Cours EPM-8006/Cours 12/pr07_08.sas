data infection; 
      input clinic t x n; 
      datalines; 
   1 1 11 36 
   1 0 10 37 
   2 1 16 20  
   2 0 22 32 
   3 1 14 19 
   3 0  7 19 
   4 1  2 16 
   4 0  1 17 
   5 1  6 17 
   5 0  0 12 
   6 1  1 11 
   6 0  0 10 
   7 1  1  5 
   7 0  1  9 
   8 1  4  6 
   8 0  6  7 
   run;

   /* Analyse conditionnelle */

proc logistic data=infection;
  model x/n = t;
  strata clinic;
run;

/* Analyse par estimation d'équations généralisées (GEE)
   pour fin de comparaison.
   (Permet de voir différence entre effet marginal et effet individuel) 

   Attention! Seul le type=ind fonctionne avec le format de données nombre d'événements/total.
*/

proc genmod data=indiv desc;
  class clinic;
  model y = t /dist=bin;
  repeated subject=clinic / type=ind;
run;
