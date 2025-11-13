data arthritis;
     infile '/workspaces/workspace/Données EPM-8006/arthritis.txt';
     input id trt age y1 y2 y3 y4;

**********************************************************;
*   Re-scale baseline age in units of 10 years         *;
**********************************************************;
age=age/10;
run;

title1 Proportional odds regression model for global impression scale at month 6;
title2 Arthritis Clinical Trial;

* Analyse avec la procédure genmod;
proc genmod des;
     model y4 = age trt / dist=mult link=cumlogit;
	 estimate "trt" trt 1 / exp;
run;

* Analyse avec la procédure logistic;
proc logistic des data=arthritis desc;
     model y4 = age trt;
/* On peut seulement obtenir des valeurs prédites, pas de résidus */
OUTPUT OUT = sortie_ordinal P = predit;
run;

proc logistic;
     model y4 = age trt / link=glogit;
run;
