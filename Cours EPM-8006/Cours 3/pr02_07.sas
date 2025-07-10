libname mylib '/workspaces/workspace/Données EPM-8006';
data pol;
  set mylib.chp05;
  * Avec proc gam, une variable réponse binaire doit prendre les valeurs 0 ou 1;
  if pds <= 2500 then y = 0; else y = 1;
  if prem = 0 then premat = 0; else premat = 1;
run;

* Lissage par la régression locale pondérée (loess);
* 4 degrés de liberté;
proc gam data=pol;
model Y=loess(AGE,df=4) / dist=binomial;
output  out=AGE p uclm lclm;
run;

*proc print; run;

proc sort data=age out=plot_age; by age; run;

symbol interpol=join;

proc gplot data=plot_age;
plot P_age*age=2 uclm_age*age=3 lclm_age*age=3/overlay  frame;
run;

* Lissage par la régression locale pondérée (loess);
* 8 degrés de liberté;
proc gam data=pol;
model Y=loess(AGE,df=8) / dist=binomial;
output  out=AGE p uclm lclm;
run;

proc sort data=age out=plot_age; by age; run;

symbol interpol=join;

proc gplot data=plot_age;
plot P_age*age=2 uclm_age*age=3 lclm_age*age=3/overlay  frame;
run;

* Lissage par des splines;
* 4 degrés de liberté;
proc gam data=pol;
model Y=spline(AGE,df=4) / dist=binomial;
output  out=AGE p uclm lclm;
run;

proc sort data=age out=plot_age; by age; run;

symbol interpol=join;

proc gplot data=plot_age;
plot P_age*age=2 uclm_age*age=3 lclm_age*age=3/overlay  frame;
run;
