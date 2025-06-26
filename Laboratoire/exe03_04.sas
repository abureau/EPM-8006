/* Analyse de l'�chantillon appari� pour l'�ge */
libname modeli "C:\Users\etudiant\Documents\EPM-8006\donnees";
data exe08_04; set modeli.exm08_04;
 t=2-cas;
 if membran=1 then membran=1; else membran=0;
 run;

/* Analyse conditionnelle for�ant un appariement suppl�mentaire avec l'�ge gestationnel
   (non recommand�) */
proc phreg;
  model t*cas(0)=membran / ties=discrete rl;
  strata age gest;
run;

proc logistic data=exe08_04 descending;
  model cas=membran;
  strata age gest;
run;

/* Analyse o� on ajuste pour l'�ge gestationnel (recommand�e) */
proc phreg data=exe08_04;
  model t*cas(0)=membran gest / ties=discrete rl;
  strata age;
run;

/* Avec proc logistic, on peut faire sortir les r�sidus, et v�rifier la lin�arit� */
proc logistic data=exe08_04 descending;
  model cas=membran gest;
  strata age;
OUTPUT OUT=PRED pred=prob xbeta=xb reschi=rchi h=hm dfbetas=_all_ c=dc;
run;
proc sgplot data=pred;
	SCATTER X = gest Y = rchi;
	LOESS X = gest Y = rchi / smooth=0.8;
	REFLINE 0;
RUN;

/* Analyse d'un appariement cr�� � partir de la cohorte */
data res; set modeli.chp04;
  if prem=1 then cas=1; else cas=0;
  t=2-cas;
  if membran=1 then membran=1; else membran=0;
proc phreg;
  model t*cas(0)=membran / ties=discrete rl;
  strata age gest;
run;

proc logistic data=res descending;
  model cas=membran;
  strata age gest;
run;

proc freq data=res;
tables age*gest*cas;
run;
