/* � ex�cuter suite � la cr�ation du jeu de donn�es amenanalyse dans le programme amenorrhee.sas */

ods select estimates; 
ods output estimates=estim;
proc glimmix method=laplace data=amenanalyse;
by _imputation_;
class id;
model y = dose temps temps*temps dose*temps dose*temps*temps / dist=bin;
random intercept / subject=id;
estimate "Effet temps 1" dose 1 dose*temps 1;
estimate "Effet temps 2" dose 1 dose*temps 2;
run;
proc sort data=estim;
by Label;

proc mianalyze data=estim;
  modeleffects estimate;
  stderr stderr; 
  by Label;
ods output parameterEstimates=estimimpute;
  run;
