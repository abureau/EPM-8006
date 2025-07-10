data arthritis;
     infile '/workspaces/workspace/Données EPM-8006/arthritis.txt';
     input id trt age y1 y2 y3 y4;

data arthritis;
     set arthritis;
     y=y1; month=0; output;
     y=y2; month=2; output;
     y=y3; month=4; output;
     y=y4; month=6; output;
run;
 
data arthritis;
     set arthritis;
     if y=. then delete;
**********************************************************;
*   Transform  month = square-root(month)            *;
**********************************************************;
sqrtmonth=month**0.5;
run;

title1 Marginal proportional odds regression model for global impression scale;
title2 Arthritis Clinical Trial;

proc genmod des;
     class id;
     model y = trt sqrtmonth trt*sqrtmonth / dist=mult link=cumlogit type3 wald;
     repeated subject=id / type=ind;
	 estimate "trt" trt 1 trt*sqrtmonth 2 / exp;	 
run;

/* Analyse conditionnelle pas supportée */
proc logistic;
 model y =  sqrtmonth ;
 strata id;
 run;
