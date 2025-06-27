DATA resp;
   INPUT center id treatment $ sex $ age baseline 
   visit1-visit4 @@;
   visit=1;  outcome=visit1;  OUTPUT;   
   visit=2;  outcome=visit2;  OUTPUT;   
   visit=3;  outcome=visit3;  OUTPUT;   
   visit=4;  outcome=visit4;  OUTPUT;   
   DATALINES;
1  53 A F  32 1  2 2 4 2  2  30 A F  37 1  3 4 4 4  
1  18 A F  47 2  2 3 4 4  2  52 A F  39 2  3 4 4 4  
1  54 A M  11 4  4 4 4 2  2  23 A F  60 4  4 3 3 4  
1  12 A M  14 2  3 3 3 2  2  54 A F  63 4  4 4 4 4  
1  51 A M  15 0  2 3 3 3  2  12 A M  13 4  4 4 4 4  
1  20 A M  20 3  3 2 3 1  2  10 A M  14 1  4 4 4 4  
1  16 A M  22 1  2 2 2 3  2  27 A M  19 3  3 2 3 3  
1  50 A M  22 2  1 3 4 4  2  16 A M  20 2  4 4 4 3  
1   3 A M  23 3  3 4 4 3  2  47 A M  20 2  1 1 0 0  
1  32 A M  23 2  3 4 4 4  2  29 A M  21 3  3 4 4 4  
1  56 A M  25 2  3 3 2 3  2  20 A M  24 4  4 4 4 4  
1  35 A M  26 1  2 2 3 2  2   2 A M  25 3  4 3 3 1  
1  26 A M  26 2  2 2 2 2  2  15 A M  25 3  4 4 3 3  
1  21 A M  26 2  4 1 4 2  2  25 A M  25 2  2 4 4 4  
1   8 A M  28 1  2 2 1 2  2   9 A M  26 2  3 4 4 4  
1  30 A M  28 0  0 1 2 1  2  49 A M  28 2  3 2 2 1  
1  33 A M  30 3  3 4 4 2  2  55 A M  31 4  4 4 4 4  
1  11 A M  30 3  4 4 4 3  2  43 A M  34 2  4 4 2 4  
1  42 A M  31 1  2 3 1 1  2  26 A M  35 4  4 4 4 4  
1   9 A M  31 3  3 4 4 4  2  14 A M  37 4  3 2 2 4  
1  37 A M  31 0  2 3 2 1  2  36 A M  41 3  4 4 3 4  
1  23 A M  32 3  4 4 3 3  2  51 A M  43 3  3 4 4 2  
1   6 A M  34 1  1 2 1 1  2  37 A M  52 1  2 1 2 2  
1  22 A M  46 4  3 4 3 4  2  19 A M  55 4  4 4 4 4  
1  24 A M  48 2  3 2 0 2  2  32 A M  55 2  2 3 3 1  
1  38 A M  50 2  2 2 2 2  2   3 A M  58 4  4 4 4 4  
1  48 A M  57 3  3 4 3 4  2  53 A M  68 2  3 3 3 4  
1   5 P F  13 4  4 4 4 4  2  28 P F  31 3  4 4 4 4  
1  19 P F  31 2  1 0 2 2  2   5 P F  32 3  2 2 3 4  
1  25 P F  35 1  0 0 0 0  2  21 P F  36 3  3 2 1 3  
1  28 P F  36 2  3 3 2 2  2  50 P F  38 1  2 0 0 0  
1  36 P F  45 2  2 2 2 1  2   1 P F  39 1  2 1 1 2  
1  43 P M  13 3  4 4 4 4  2  48 P F  39 3  2 3 0 0  
1  41 P M  14 2  2 1 2 3  2   7 P F  44 3  4 4 4 4  
1  34 P M  15 2  2 3 3 2  2  38 P F  47 2  3 3 2 3  
1  29 P M  19 2  3 3 0 0  2   8 P F  48 2  2 1 0 0  
1  15 P M  20 4  4 4 4 4  2  11 P F  48 2  2 2 2 2  
1  13 P M  23 3  3 1 1 1  2   4 P F  51 3  4 2 4 4  
1  27 P M  23 4  4 2 4 4  2  17 P F  58 1  4 2 2 0  
1  55 P M  24 3  4 4 4 3  2  39 P M  11 3  4 4 4 4  
1  17 P M  25 1  1 2 2 2  2  40 P M  14 2  1 2 3 2  
1  45 P M  26 2  4 2 4 3  2  24 P M  15 3  2 2 3 3  
1  40 P M  26 1  2 1 2 2  2  41 P M  15 4  3 3 3 4  
1  44 P M  27 1  2 2 1 2  2  33 P M  19 4  2 2 3 3  
1  49 P M  27 3  3 4 3 3  2  13 P M  20 1  4 4 4 4  
1  39 P M  28 2  1 1 1 1  2  34 P M  20 3  2 4 4 4  
1   2 P M  28 2  0 0 0 0  2  45 P M  33 3  3 3 2 3  
1  14 P M  30 1  0 0 0 0  2  22 P M  36 2  4 3 3 4  
1  10 P M  37 3  2 3 3 2  2  18 P M  38 4  3 0 0 0  
1  31 P M  37 1  0 0 0 0  2  35 P M  42 3  2 2 2 2  
1   7 P M  43 2  3 2 4 4  2  44 P M  43 2  1 0 0 0  
1  52 P M  43 1  1 1 3 2  2   6 P M  45 3  4 2 1 2  
1   4 P M  44 3  4 3 4 2  2  46 P M  48 4  4 0 0 0  
1   1 P M  46 2  2 2 2 2  2  31 P M  52 2  3 4 3 4   
1  46 P M  49 2  2 2 2 2  2  42 P M  66 3  3 3 4 4   
1  47 P M  63 2  2 2 2 2  
;
DATA resp2; SET resp; 
   dichot=(outcome=3 or outcome=4); 
   di_base = (baseline=3 or baseline=4); 
RUN; 
PROC PRINT; RUN;



/*Statistiques descriptives*/
PROC MEANS DATA = resp2;
	CLASS treatment;
	VAR baseline age;
RUN;

PROC FREQ DATA = resp2;
	TABLE treatment*(sex center);
RUN;
*Âge, mesure initiale et centre semblent équilibrés.
*Sex est assez déséquilibré entre les deux groupes;

PROC SORT DATA = resp2; BY visit treatment; RUN;
PROC MEANS DATA = resp2;
	BY visit treatment;
	VAR dichot;
	OUTPUT OUT = moyennes MEAN = dichot;
RUN;

DATA moyennes2;
	SET moyennes;
	Cote = log(dichot/(1 - dichot));
RUN;

PROC SGPLOT DATA = moyennes;
	SERIES X = visit Y = dichot / GROUP = treatment;
	XAXIS LABEL = "Visite";
	YAXIS LABEL = "Bon statut respiratoire" MIN = 0 MAX = 1;
RUN;

PROC SGPLOT DATA = moyennes2;
	SERIES X = visit Y = Cote / GROUP = treatment;
	XAXIS LABEL = "Visite";
	YAXIS LABEL = "log-Cote de bon statut respiratoire";
RUN;

*GEE avec centre;
PROC SORT DATA = resp2; BY id visit; RUN;
* Modèle log-binomial;
PROC GENMOD DATA = resp2 DESCENDING;
	CLASS center id treatment sex visit;
	MODEL dichot = treatment|visit sex age baseline center
		/ DIST = poisson LINK = log TYPE3 WALD;
	REPEATED SUBJECT = id(center) / TYPE = AR(1);
	LSMEANS treatment / DIFF EXP CL;
	LSMEANS treatment*visit;
RUN; 
 
/*QIC = 1719.3262 pour AR(1)
QIC = 1740.9789 pour CS
QIC = 1730.8814 pour UN, on choisit AR(1)*/


PROC MEANS DATA = resp2;
	VAR age baseline;
RUN;

PROC GENMOD DATA = resp2 DESCENDING 
	PLOTS = (DFBETA COOKSD RESCHI); *On peut faire les diagnostiques avec ça;
	CLASS id treatment sex visit center;
	MODEL dichot = treatment|visit sex age baseline center
		/ DIST = poisson LINK = log TYPE3 WALD;
	ESTIMATE "A-1" intercept 1 treatment 1 0 visit 1 0 0 0 treatment*visit 1 0 0 0 0 0 0 0 
					sex 0.5 0.5 age 33.2792793 baseline 2.3783784 center 0.5 0.5;
	ESTIMATE "A-2" intercept 1 treatment 1 0 visit 0 1 0 0 treatment*visit 0 1 0 0 0 0 0 0 
					sex 0.5 0.5 age 33.2792793 baseline 2.3783784  center 0.5 0.5;
	ESTIMATE "A-3" intercept 1 treatment 1 0 visit 0 0 1 0 treatment*visit 0 0 1 0 0 0 0 0 
					sex 0.5 0.5 age 33.2792793 baseline 2.3783784  center 0.5 0.5;
	ESTIMATE "A-4" intercept 1 treatment 1 0 visit 0 0 0 1 treatment*visit 0 0 0 1 0 0 0 0 
					sex 0.5 0.5 age 33.2792793 baseline 2.3783784  center 0.5 0.5;
	ESTIMATE "A"   intercept 1 treatment 1 0 visit 0.25 0.25 0.25 0.25 treatment*visit 0.25 0.25 0.25 0.25 0 0 0 0 
					sex 0.5 0.5 age 33.2792793 baseline 2.3783784  center 0.5 0.5;
	ESTIMATE "P"   intercept 1 treatment 0 1 visit 0.25 0.25 0.25 0.25 treatment*visit 0 0 0 0 0.25 0.25 0.25 0.25
					sex 0.5 0.5 age 33.2792793 baseline 2.3783784  center 0.5 0.5;
	ESTIMATE "A-P" treatment 1 -1 treatment*visit 0.25 0.25 0.25 0.25 -0.25 -0.25 -0.25 -0.25;
	LSMEANS treatment*visit / EXP;
	REPEATED SUBJECT = id(center) / TYPE = AR(1);
	LSMEANS treatment / DIFF EXP CL;
	OUTPUT OUT = sortie P = predit COOKSD = cook RESCHI = resid 
	DFBETA = _all_;
RUN; 

* Modèle logistique;
PROC GENMOD DATA = resp2 DESCENDING;
	CLASS center id treatment sex visit;
	MODEL dichot = treatment|visit sex age baseline center
		/ DIST = binomial LINK = logit TYPE3 WALD aggregate scale=pearson;
	REPEATED SUBJECT = id(center) / TYPE = AR(1) modelse;
	LSMEANS treatment / DIFF EXP CL;
	LSMEANS treatment*visit/ EXP;
	OUTPUT OUT = sortie P = predit COOKSD = cook RESCHI = resid 
	DFBETA = _all_;
RUN;
*Où en faisant sortir les résultats;
PROC PRINT DATA = sortie (OBS = 10); RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = age Y = resid; 
	LOESS X = age Y = resid / smooth=0.5;
	REFLINE 0;
RUN;

*Le graphique semble montrer une tendance,
mais le loess suggère que non;
PROC SGPLOT DATA = sortie;
	SCATTER X = baseline Y = resid; 
	LOESS X = baseline Y = resid;
	REFLINE 0;
RUN;

PROC MEANS DATA = sortie;
	CLASS baseline;
	VAR resid;
RUN;

PROC SORT DATA = sortie; BY DESCENDING cook; RUN;
PROC PRINT DATA = sortie (OBS = 20); RUN;

DATA sortie2;
	SET sortie;
	dfb2 = abs(dfbeta2);
RUN;

PROC SORT DATA = sortie2; BY DESCENDING dfb2; RUN;
PROC PRINT DATA = sortie2 (OBS = 20); RUN;

