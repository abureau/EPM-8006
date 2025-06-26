data pr03_04; set sasuser.EXM08_04;

TIME=2-CAS;

IF PARIT=0 THEN PAR=1; ELSE PAR=0;
run;
PROC PHREG data=pr03_04;
 MODEL TIME*CAS(0)=PAR / TIES=EXACT RL;
 STRATA STR;
RUN;
PROC PHREG;
 MODEL TIME*CAS(0)=PAR / TIES=DISCRETE RL;
 STRATA STR;
RUN;
* M�me analyse avec PROC LOGISTIC;

proc logistic descending;
      model cas = par;
      strata STR;
run;

* Fa�on alternative de former les strates � partir des variables de stratification;
proc logistic descending;
      model cas = par;
      strata age;
run;
