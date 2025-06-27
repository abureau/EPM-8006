* a) Méthode de la variable indicatrice;
data ectopic_indic;
  set sasuser.ectopic_donnees;
  if chlamydia = . then do;
    r = 0;
    chlamydia = 0;
  end;
  else r = 1;
  uchlamydia = r*chlamydia;
run;

/* Vérification de la confondance */

proc logistic data=ectopic_indic desc;
  model pregnancy = gonnorhoea r uchlamydia contracept sexpatr;
run;

proc logistic data=ectopic_indic desc;
  model pregnancy = gonnorhoea r uchlamydia contracept;
run;

proc logistic data=ectopic_indic desc;
  model pregnancy = gonnorhoea r uchlamydia sexpatr;
run;

proc logistic data=ectopic_indic desc;
  model pregnancy = gonnorhoea r uchlamydia;
run;

* Modèle avec partenaires et contraceptifs préférable;

* b) Méthode de Cain et Breslow ;

* Modèle ajusté pour partenaires sexuels multiples et contraception;

/* Analyse de l'échantillon entier (phase 1) avec les variables qui 
   n'ont pas de valeurs manquantes */

proc logistic data=sasuser.ectopic_donnees desc covout outest=tb;
  model pregnancy = gonnorhoea contracept sexpatr / covb;
run;

data est_tb; set tb;
 keep gonnorhoea;
proc transpose out=trans;
data tb; set trans;
 keep etb vtb;
 etb=col1; vtb=col3;
run;

/* Analyse de l'échantillon réduit sans valeurs manquantes (phase 2) avec le même modèle 
   que précédemment (variables qui n'ont pas de valeurs manquantes)
*/
proc logistic data=sasuser.ectopic_donnees desc covout outest=pb;
  where chlamydia ne .;
  model pregnancy = gonnorhoea contracept sexpatr / covb;
run;

data est_pb; set pb;
 keep gonnorhoea;
proc transpose out=trans;
data pb; set trans;
 keep epb vpb;
 epb=col1; vpb=col3;
run;

/* Analyse de l'échantillon réduit sans valeurs manquantes (phase 2) avec toutes les variables */

proc logistic data=sasuser.ectopic_donnees desc covout outest=pa;
  where chlamydia ne .;
  model pregnancy = chlamydia gonnorhoea contracept sexpatr / covb;
run;

data est_pa; set pa;
 keep gonnorhoea;
proc transpose out=trans;
data pa; set trans;
 keep epa vpa;
 epa=col1; vpa=col4;
run;

/* Combinaison des tableaux de données contenant les estimations et calcul de 
   l'estimation ajustée par la méthode Cain-Breslow du coefficient pour gonorrhée */

data tot; merge tb pb pa;
 E_b=epa+etb-epb; pmb=exp(E_b); cc=exp(epa);
  var_est=vpa+(vtb-vpb); c_tst=(epb-etb)**2/(vpb-vtb);
  proc print;
run;

/* On répète pour le modèle brut de chlamydia et gonorrhée */

/* Analyse de l'échantillon entier (phase 1) avec la variable gonorrhée seule qui 
   n'a pas de valeurs manquantes */

proc logistic data=sasuser.ectopic_donnees desc covout outest=tb;
  model pregnancy = gonnorhoea / covb;
run;

data est_tb; set tb;
 keep gonnorhoea;
proc transpose out=trans;
data tb; set trans;
 keep etb vtb;
 etb=col1; vtb=col3;
run;

/* Analyse de l'échantillon réduit sans valeurs manquantes (phase 2) avec le même modèle 
   que précédemment (variable gonorrhée qui n'a pas de valeurs manquantes)
*/
proc logistic data=sasuser.ectopic_donnees desc covout outest=pb;
  where chlamydia ne .;
  model pregnancy = gonnorhoea / covb;
run;

data est_pb; set pb;
 keep gonnorhoea;
proc transpose out=trans;
data pb; set trans;
 keep epb vpb;
 epb=col1; vpb=col3;
run;

/* Analyse de l'échantillon réduit sans valeurs manquantes (phase 2) avec chlamydia et gonorrhée */

proc logistic data=sasuser.ectopic_donnees desc covout outest=pa;
  where chlamydia ne .;
  model pregnancy = chlamydia gonnorhoea / covb;
run;

data est_pa; set pa;
 keep gonnorhoea;
proc transpose out=trans;
data pa; set trans;
 keep epa vpa;
 epa=col1; vpa=col4;
run;

/* Combinaison des tableaux de données contenant les estimations et calcul de 
   l'estimation ajustée par la méthode Cain-Breslow du coefficient pour gonorrhée
   (que nous considérons comme l'estimation brute pour cette exposition étudiée 
   ici conjointement avec la chlamydia. )*/

data tot; merge tb pb pa;
 E_b=epa+etb-epb; pmb=exp(E_b); cc=exp(epa);
  var_est=vpa+(vtb-vpb); c_tst=(epb-etb)**2/(vpb-vtb);
  proc print;
run;


* c) Imputation multiple;

/* On peut utiliser l'énoncé monotone parce que les données ont cette propriété
   (forcément satisfaite quand une seule variable a des données manquantes */
   
proc mi data=sasuser.ectopic_donnees out = ectopic_impute SEED = 743981;
  class pregnancy chlamydia gonnorhoea contracept sexpatr;
  var pregnancy gonnorhoea contracept sexpatr chlamydia;
  monotone logistic(chlamydia = pregnancy gonnorhoea contracept sexpatr);
run;

/* L'approche par équations en chaîne se résume à la même chose ici */
proc mi data=sasuser.ectopic_donnees out = ectopic_impute SEED = 743981;
  class pregnancy chlamydia gonnorhoea contracept sexpatr;
  var pregnancy gonnorhoea contracept sexpatr chlamydia;
  fcs logistic(chlamydia = pregnancy gonnorhoea contracept sexpatr);
run;


* Inspection de l'imputation;
proc freq data=ectopic_impute;
  by _imputation_;
  tables chlamydia;
run;

/* Vérification de la confondance */

proc logistic data=ectopic_impute descending;
  by _imputation_;
  model pregnancy= gonnorhoea chlamydia contracept sexpatr / covb;
  ods output ParameterEstimates=param1 CovB=covarb1;
run;

proc logistic data=ectopic_impute descending;
  by _imputation_;
  model pregnancy= gonnorhoea chlamydia contracept / covb;
  ods output ParameterEstimates=param2 CovB=covarb2;
run;

proc logistic data=ectopic_impute descending;
  by _imputation_;
  model pregnancy= gonnorhoea chlamydia sexpatr / covb;
  ods output ParameterEstimates=param3 CovB=covarb3;
run;

proc logistic data=ectopic_impute descending;
  by _imputation_;
  model pregnancy= gonnorhoea chlamydia/ covb;
  ods output ParameterEstimates=param4 CovB=covarb4;
run;

proc mianalyze parms=param1 covb=covarb1;
  modeleffects Intercept gonnorhoea chlamydia contracept sexpatr;
run;

proc mianalyze parms=param2 covb=covarb2;
  modeleffects Intercept gonnorhoea chlamydia contracept;
run;

proc mianalyze parms=param3 covb=covarb3;
  modeleffects Intercept gonnorhoea chlamydia sexpatr;
run;

proc mianalyze parms=param4 covb=covarb4;
  modeleffects Intercept gonnorhoea chlamydia;
run;
