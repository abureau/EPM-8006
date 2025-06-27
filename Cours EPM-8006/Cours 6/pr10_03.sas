data Exm13_03;
do i=1 to 270;
  if     i<=48  then do; y=1; x=1; u=1; end;
  if  48<i<=60  then do; y=1; x=1; u=0; end;
  if  60<i<=80  then do; y=1; x=0; u=1; end;
  if  80<i<=90  then do; y=1; x=0; u=0; end;
  if  90<i<=130 then do; y=2; x=1; u=1; end;
  if 130<i<=150 then do; y=2; x=1; u=0; end;
  if 150<i<=210 then do; y=2; x=0; u=1; end;
  if 210<i<=270 then do; y=2; x=0; u=0; end;
  output;
end;
run;

data exm2; set exm13_03;
z=ranuni(1);
c=0.5;
if z>c then do u=.; end;
else do; u=u; end;
/* Présentation des données de l'échantillon de la phase II */
proc freq;
tables u*y*x / nopercent nocol;
run;

data partiel; set exm2;
  if u=. then do; z=1; u=0;
  end;
  else do; z=0; u=u;
  end;
  zu=(1-z)*u;

  /* Analyse de l'association brute entre x et y dans l'étude en entier (phase I)*/
proc logistic covout outest=tb data=partiel;
 model y=x / covb;
 /* Extraction de l'estimation du coefficient et de l'estimation de sa variance */
data est_tb; set tb;
 keep x;
proc transpose out=trans;
data tb; set trans;
 keep etb vtb;
 etb=col1; vtb=col3;
run;

  /* Analyse de l'association brute entre x et y dans l'échantillon de la phase II*/
proc logistic covout outest=pb data=partiel;
 model y=x / covb;
 where z=0;
 /* Extraction de l'estimation du coefficient et de l'estimation de sa variance */
 data est_pb; set pb;
 keep x;
proc transpose out=trans;
data pb; set trans;
 keep epb vpb;
 epb=col1; vpb=col3;
run;

  /* Analyse de l'association entre x et y ajustée pour u dans l'échantillon de la phase II*/
proc logistic covout outest=pa data=partiel;
 model y=x u / covb;
 where z=0;
  /* Extraction de l'estimation du coefficient et de l'estimation de sa variance */
 data est_pa; set pa;
 keep x;
proc transpose out=trans;
data pa; set trans;
 keep epa vpa;
 epa=col1; vpa=col3;
run;

/* Combinaison des tableaux de données contenant les estimations et calcul de 
   l'estimation ajustée du coefficient de x et de l'estimation de sa variance,
   plus un test de l'hypothèse nulle que le coefficient ajusté est égale au
   coefficient brut*/
data tot; merge tb pb pa;
 E_b=epa+etb-epb; pmb=exp(E_b); cc=exp(epa);
  varest=vpa+(vtb-vpb);
  tst=(etb-epb)/sqrt(vpb-vtb);
  proc print;
run;

/* Analyse hypothétique dans laquelle la variable u est observée pour tous les sujets
   Cette analyse idéale n'est pas possible dans la réalité.*/
proc logistic data=exm13_03;
 model y=x u / covb;
run;

