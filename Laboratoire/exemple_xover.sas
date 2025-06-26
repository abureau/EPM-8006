*Lecture des données;
DATA xover;
	INPUT Sujet Trt1$ DEP1 Trt2$ DEP2;
	*Une petite astuce pour créer
	des variables pour le DEP selon
	chaque traitement;
	*(Trt1 = "for") vaut 1 si Trt1 vaut "for" et 0 sinon;
	DEPfor = DEP1*(Trt1 = "for") + DEP2*(Trt2 = "for");
	DEPsal = DEP1*(Trt1 = "sal") + DEP2*(Trt2 = "sal");
	DATALINES;
1  for  310  sal  270 
2  for  310  sal  260 
3  for  370  sal  300 
4  for  410  sal  390 
5  for  250  sal  210 
6  for  380  sal  350 
7  for  330  sal  365 
8  sal  370  for  385 
9  sal  310  for  410 
10  sal  380  for  410 
11  sal  290  for  320 
12  sal  260  for  340 
13  sal  90  for  220 
;
RUN;

*Statistiques descriptives;
PROC MEANS DATA = xover MEAN MEDIAN STD n;
	VAR DEP1 DEP2 DEPfor DEPsal;
RUN;

PROC MEANS DATA = xover MEAN MEDIAN STD n;
	CLASS trt1;
	VAR DEP1 DEP2;
RUN;

PROC CORR DATA = xover COV;
	VAR DEP1;
	WITH DEP2;
RUN;

*Création d'un jeu de données format long;
DATA Period1;
	SET xover;
	DEP = DEP1;
	Trt = Trt1;
	period = 1;
	KEEP Sujet DEP trt period;
RUN;

DATA Period2;
	SET xover;
	DEP = DEP2;
	Trt = Trt2;
	period = 2;
	KEEP Sujet DEP trt period;
RUN;

DATA long;
	SET Period1 Period2;
	*Création d'une nouvelle variable;
	*La fonction compress concatène les valeurs de différentes variables; 
	period_trt = compress(period||"_"||trt);
	*Par exemple si period = 1 et trt = sol, la valeur
	de period_trt = 1_sol. Le _ est ajouté au centre par le "_" du compress;
RUN;

*Autres statistiques descriptives;
PROC SORT DATA = long; BY trt; RUN;
PROC BOXPLOT DATA = long;
	PLOT DEP*trt / BOXSTYLE = SCHEMATIC;
RUN; QUIT;

PROC SORT DATA = long; BY period; RUN;
PROC BOXPLOT DATA = long;
	PLOT DEP*period / BOXSTYLE = SCHEMATIC;
RUN; QUIT;

PROC SORT DATA = long; BY period_trt; RUN;
PROC BOXPLOT DATA = long;
	PLOT DEP*period_trt / BOXSTYLE = SCHEMATIC;
RUN; QUIT;



*Modèle classique;
PROC MIXED DATA = long;
	CLASS trt period sujet;
	MODEL DEP = trt|period / DDFM = BW VCIRY INFLUENCE (ITER = 5 EST) OUTPM = sortie SOLUTION ALPHA = 0.05;
	RANDOM intercept / SUBJECT = sujet S; *l'option S pour obtenir les solutions des effets aléatoires;
	ESTIMATE "for1" intercept 1 trt 1 0 period 1 0 trt*period 1 0 0 0;
	ESTIMATE "for2" intercept 1 trt 1 0 period 0 1 trt*period 0 1 0 0;
	ESTIMATE "for" intercept 1 trt 1 0 period 0.5 0.5 trt*period 0.5 0.5 0 0;
	ESTIMATE "sal1" intercept 1 trt 0 1 period 1 0 trt*period 0 0 1 0;
	ESTIMATE "sal2" intercept 1 trt 0 1 period 0 1 trt*period 0 0 0 1;
	ESTIMATE "sal" intercept 1 trt 0 1 period 0.5 0.5 trt*period 0 0 0.5 0.5;
	ESTIMATE "for - sal" trt 1 -1 trt*period 0.5 0.5 -0.5 -0.5;
	LSMEANS trt / DIFF CL;
	LSMEANS period /DIFF CL;
	SLICE trt*period / DIFF SLICEBY = period CL;
	LSMEANS trt*period / DIFF CL;
RUN; 
*Remarquez la correspondance entre les résultats obtenus avec ESTIMATE et ceux obtenus avec 
LSMEANS; 
*Remarquez aussi la correspondance entre les moyennes estimées et les moyennes obtenues avec le modèle.
Ceci est dû au fait que le modèle est saturé et que le devis est équilibré (13 obs pour sol, 13 obs pour sal,
13 obs pour period 1, 13 obs pour period 2. Il n'y a qu'un léger déséquilibre pour l'interaction.);

/*En théorie, il faudrait comme toujours vérifier
les différentes hypothèses du modèle à cette étape.
Entre autres, on remarque au graphique précédent une
observation extrême qu'on pourrait essayer de retirer.*/



*Analyse incorrecte négligeant la corrélation entre les observations sur un même sujet;
PROC MIXED DATA = long;
	CLASS trt period sujet;
	MODEL DEP = trt|period / DDFM = BW VCIRY INFLUENCE OUTPM = sortie SOLUTION ALPHA = 0.05;
	*RANDOM intercept / SUBJECT = sujet;
	LSMEANS trt / DIFF CL;
RUN; 



*Exemples d'autres modèles possibles;
PROC MIXED DATA = long;
	CLASS trt period sujet;
	MODEL DEP = trt|period / DDFM = BW;
	REPEATED period / SUBJECT = sujet TYPE = UN;
	LSMEANS trt / DIFF;
	SLICE trt*period / DIFF SLICEBY = period;
RUN; 

PROC GENMOD DATA = long;
	CLASS trt period sujet;
	MODEL DEP = trt|period / DIST = normal LINK = ID TYPE3;
	REPEATED SUBJECT = sujet / TYPE = CS;
	LSMEANS trt / DIFF;
	SLICE trt*period / DIFF SLICEBY = period;
RUN; 

