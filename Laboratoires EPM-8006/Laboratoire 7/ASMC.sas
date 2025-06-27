data sids;
  input x y n;
  cards;
  0 0 663
  0 1 602
  1 0 134
  1 1 173
  ;
run;

* Augmentation du jeu de données avec la variable T;

data don0;
  set sids;
  t=0;
run;
data don1;
  set sids;
  t=1;
run;

data dona;
  set don0 don1;
run;

* Répétion du jeu de données;

%macro enumdona(nbr=); 
%do n=1 %to &nbr;
	dona
	%end;
%mend enumdona;

/* nbr= nbre de fois que le fichier doit être répété */
data donarep;
set %enumdona(nbr=100);
run;

data donarep;
  set donarep;
  rep = floor((_n_-1)/8)+1;
run;

* Génération de 100 valeurs des paramètres à partir de leur distribution a priori;
data simpriori;
do rep = 1 to 100;
  moyT = log(0.066/0.9334);
  moyTX = log(13.5);
  alphaT = moyT + 0.4*rannor(10);
  alphaTX = moyTX + 0.5*rannor(11);
  alphaTY = sqrt(0.5)*rannor(12);
  alphaTXY = 0.25*rannor(13);
  output;
end;
run;

data donai;
  merge simpriori donarep;
  by rep;
  * Calcul de la probabilité que T = 1;
  eta = alphaT + alphaTX*x + alphaTY*y + alphaTXY*x*y;
  pi1 = exp(eta)/(1+exp(eta));
  if t=1 then pit = pi1;
  else pit = 1 - pi1;
  * Calcul des fréquences espérées;
  nt = n*pit;
run;

ods trace off;

* Estimation de log(RC) entre Y et T dans les 100 réplicats;
proc logistic data=donai descending;
  model y = t;
  weight nt;
  by rep;
  ods output ParameterEstimates=estim;
run;

data estimb;
  set estim;
/* Échantillonnage du log(RC) à partir de sa distribution a posteriori
   pour prendre en compte la variabilité dans les données.
   (aussi appelé bootstrap paramétrique) */
  betar = estimate + stderr*rannor(14);
* Correction du biais statistique;
  betac = 2*estimate - betar;
* Calcul du RC;
  RCr = exp(betar);
  RCc = exp(betac);
run;

proc sort data=estimb;
by variable;
run;

* Inspection de la distribution a posteriori des estimations de coefficients;
proc univariate data=estimb;
  var estimate betar betac;
  by variable;
run;

* Inspection de la distribution a posteriori des estimations du RC;
proc univariate data=estimb;
  var RCr RCc;
  by variable;
run;

* Calcul des quantiles 2.5 , 50 (médiane) et 97.5;
proc stdize data=estimb outstat=statsb pctlpts=2.5 50 97.5;
  var RCr RCc;
  by variable;
run;
