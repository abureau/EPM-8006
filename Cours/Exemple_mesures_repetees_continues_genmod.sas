/*Lecture des donn�es*/
DATA seizure;
	INFILE "C:\Users\AlexandreBureau\Documents\EPM-8006\donnees\seizure.data";
	INPUT ID Counts Visit TX Age Weeks;
RUN;

/*Afficher les donn�es*/
PROC PRINT DATA = seizure (OBS = 10); RUN;

/*Le jeu de donn�es est dans ce qu'on appelle un format long, c'est-�-dire
que chaque ligne repr�sente une visite pour un sujet. C'est ce qu'il
faut pour effectuer les analyses.*/

/* Cr�er un jeu de donn�es avec les valeurs au d�part
plac�e dans des variables s�par�es*/
DATA baseline;
	SET seizure;
	WHERE Visit = 0;
	Counts0 = counts;
	Age0 = Age;
	KEEP ID Counts0 Age0;
RUN;
PROC PRINT DATA = baseline (OBS = 10); RUN;


PROC SORT DATA = baseline; BY id; RUN;
PROC SORT DATA = seizure; BY id; RUN;

DATA seizure2;
	MERGE seizure baseline;
	BY ID;
	IF Visit = 0 THEN DELETE;
RUN;
PROC PRINT DATA = seizure2 (OBS = 10); RUN;

/*Effectuer quelques statistiques descriptives / graphiques*/

PROC SORT DATA = seizure2; BY tx; RUN;
PROC MEANS DATA = seizure2;
	BY TX;
	WHERE visit = 1;
	VAR counts0 age0;
RUN;

PROC SORT DATA = seizure2; BY visit TX; RUN;
PROC MEANS DATA = seizure2 NOPRINT;
	BY visit TX;
	VAR Counts;
	OUTPUT OUT = stat_desc MEAN = m_counts;
RUN;

DATA stat_desc2;
	MERGE seizure2 stat_desc;
	BY visit TX;
RUN;

PROC SGPLOT DATA = stat_desc2;
	SCATTER X = visit Y = counts / GROUP = TX;
	SERIES X = visit Y = m_counts / GROUP = TX;
RUN;

PROC SGPLOT DATA = stat_desc2;
	SERIES X = visit Y = m_counts / GROUP = TX;
RUN;

PROC TABULATE DATA = seizure2;
	CLASS VISIT TX;
	VAR counts;
	TABLE TX, visit*counts = ""*(MEAN = "Moy" MEDIAN = "Med" STD = "�-T");
RUN;


/*GEE*/

/*Approche contrastes pr�-sp�cifi�s*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC GENMOD DATA = seizure2;
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX counts0 / DIST = NORMAL LINK = ID;
	REPEATED SUBJECT = ID / TYPE = AR(1) corrw ; 
	ESTIMATE "Tx � visit 1"      intercept 1  visit 1 tx 1 0 visit*tx 1 0 counts0 31.22; 
	ESTIMATE "Placebo � visit 1" intercept 1  visit 1 tx 0 1 visit*tx 0 1 counts0 31.22; 
	ESTIMATE "Diff Tx - Placebo � visit 1" tx 1 -1 visit*tx 1 -1;
	LSMEANS TX / DIFF AT VISIT = 1 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 2 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 3 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 4 ALPHA = 0.05;
	CONTRAST "test pente progabide" visit 1 visit*tx 1 0 / WALD;
	OUTPUT OUT = resid DFBETA = (dfbeta1-dfbeta5) RESRAW = resid;
RUN;

/*Approche s�quentielle*/
/*Selon cette approche, on aurait r�alis�
qu'on ne dispose pas de preuves que l'effet du
traitement varie dans le temps (p = 0.7802).
On aurait ensuite estim� l'effet moyen du traitement
sur les p�riodes combin�es:
1re fa�on : effet du traitement au temps moyen*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC GENMOD DATA = seizure2;
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX counts0 / DIST = NORMAL LINK = ID TYPE3 WALD;
	REPEATED SUBJECT = ID / TYPE = AR(1) corrw ; 
	/*Avec un contraste:*/
	ESTIMATE "Effet moyen traitement" TX 1 -1 TX*visit 2.5 -2.5;
	/*Avec un LSMEANS:*/
	LSMEANS TX / DIFF AT visit = 2.5 ALPHA = 0.05;
	/*Attention! Les moyennes de LSMEANS sont calcul�es
	par d�faut pour les variables continues = leur moyenne*/
	*	OUTPUT OUT = resid DFBETA = (dfbeta1-dfbeta5) RESRAW = resid;
RUN;

/*L'�criture de l'�nonc� ESTIMATE fait un
meilleur parall�le avec les param�tres du mod�le
math�matique quand on utilise PARAM = REF,
mais impossible d'utiliser l'�nonc� LSMEANS*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC GENMOD DATA = seizure2;
	CLASS ID TX(REF = first) / PARAM = REF;
	MODEL counts = visit|TX counts0 / DIST = NORMAL LINK = ID TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1) corrw ; 
	/*Avec un contraste:*/
	ESTIMATE "Effet moyen traitement" TX 1 TX*visit 2.5;
RUN;

/* 2e fa�on: on retire le terme d'interaction /*
PROC GENMOD DATA = seizure2;
	CLASS ID TX(REF = first) / PARAM = REF;
	MODEL counts = visit TX counts0 / DIST = NORMAL LINK = ID TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1) corrw ; 
RUN;


/*V�rification des hypoth�ses*/

*Cr�ation d'un jeu de donn�es avec les
valeurs absolues des dfbetas;
DATA resid2;
	SET resid;
	dfb2 = abs(dfbeta2); *DFBeta pour visit;
	dfb3 = abs(dfbeta3); *DFbeta pour TX;
	dfb5 = abs(dfbeta5); *DFbeta pour visit*TX;
	*Le DFB pour l'ordonn�e � l'origine et pour counts0
	ne sont pas tr�s importants. Ce ne sont pas les param�tres
	qu'on va interpr�ter;
RUN;

*V�rification de la lin�arit� de l'effet de la visite;
PROC SGPLOT DATA = resid;
	SCATTER X = visit Y = resid / GROUP = tx;
	LOESS X = Visit Y = resid / GROUP = tx;
RUN; QUIT;
*Il semble y avoir des valeurs extr�mes, mais pas de probl�me pour la lin�arit�;


PROC SORT DATA = resid; BY TX; RUN;
PROC BOXPLOT DATA = resid;
	PLOT resid*TX /BOXSTYLE = SCHEMATIC;
RUN; QUIT;
*On constate tr�s clairement des valeurs extr�mes;

*Donn�es influentes ou extr�mes;
PROC SORT DATA = resid2; BY DESCENDING dfb2; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb2 ID VISIT COUNTS COUNTS0; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb2; RUN;

PROC SORT DATA = resid2; BY DESCENDING dfb3; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb3 ID VISIT COUNTS COUNTS0; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb3; RUN;

PROC SORT DATA = resid2; BY DESCENDING dfb5; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb5 ID VISIT COUNTS COUNTS0; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb5; RUN;
*Il y a assez clairement des valeurs influentes sur l'effet du traitement;

*Je vais essayer un mod�le avec fonction de lien log pour r�duire l'influence
des nombres de crises �lev�s;
*Je vais aussi prendre une transformation du counts0;

DATA seizure3;
	SET seizure2;
	logC0 = log(counts0);
RUN;


PROC SORT DATA = seizure3; BY ID Visit; RUN;
PROC GENMOD DATA = seizure3;
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX logC0 / DIST = NORMAL LINK = LOG TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1); 
	LSMEANS TX / DIFF AT VISIT = 1 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 2 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 3 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 4 ALPHA = 0.05 EXP;
	OUTPUT OUT = resid DFBETA = (dfbeta1-dfbeta5) RESRAW = resid;
RUN;



/*V�rification des hypoth�ses*/

*Cr�ation d'un jeu de donn�es avec les
valeurs absolues des dfbetas;
DATA resid2;
	SET resid;
	dfb2 = abs(dfbeta2); *DFBeta pour visit;
	dfb3 = abs(dfbeta3); *DFbeta pour TX;
	dfb5 = abs(dfbeta5); *DFbeta pour visit*TX;
	*Le DFB pour l'ordonn�e � l'origine et pour counts0
	ne sont pas tr�s importants. Ce ne sont pas les param�tres
	qu'on va vraiment interpr�ter;
RUN;

*V�rification de la lin�arit� de l'effet de la visite;
PROC SGPLOT DATA = resid;
	SCATTER X = visit Y = resid / GROUP = tx;
	LOESS X = Visit Y = resid / GROUP = tx;
RUN; QUIT;
*Il reste encore une valeur extr�me.;


PROC SORT DATA = resid; BY TX; RUN;
PROC BOXPLOT DATA = resid;
	PLOT resid*TX /BOXSTYLE = SCHEMATIC;
RUN; QUIT;
*On constate tr�s clairement cette valeur extr�mes;

*Donn�es influentes ou extr�mes;
PROC SORT DATA = resid2; BY DESCENDING dfb2; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb2 ID VISIT COUNTS COUNTS0; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb2; RUN;

PROC SORT DATA = resid2; BY DESCENDING dfb3; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb3 ID VISIT COUNTS COUNTS0; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb3; RUN;

PROC SORT DATA = resid2; BY DESCENDING dfb5; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb5 ID VISIT COUNTS COUNTS0; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb5; RUN;


*Je vais refaire l'analyse sans cette observation;
PROC SORT DATA = seizure3; BY ID Visit; RUN;
PROC GENMOD DATA = seizure3;
	WHERE NOT (ID = 207 AND VISIT = 1);
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX logC0 / DIST = NORMAL LINK = LOG TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1); 
	LSMEANS TX / DIFF AT VISIT = 1 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 2 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 3 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 4 ALPHA = 0.05 EXP;
	OUTPUT OUT = resid DFBETA = (dfbeta1-dfbeta5) RESRAW = resid;
RUN;

/*V�rification des hypoth�ses*/

*Cr�ation d'un jeu de donn�es avec les
valeurs absolues des dfbetas;
DATA resid2;
	SET resid;
	dfb2 = abs(dfbeta2); *DFBeta pour visit;
	dfb3 = abs(dfbeta3); *DFbeta pour TX;
	dfb5 = abs(dfbeta5); *DFbeta pour visit*TX;
	*Le DFB pour l'ordonn�e � l'origine et pour counts0
	ne sont pas tr�s importants. Ce ne sont pas les param�tres
	qu'on va vraiment interpr�ter;
RUN;

*V�rification de la lin�arit� de l'effet de la visite;
PROC SGPLOT DATA = resid;
	SCATTER X = visit Y = resid / GROUP = tx;
	LOESS X = Visit Y = resid / GROUP = tx;
RUN; QUIT;
*Il reste encore une valeur extr�me.;

*Donn�es influentes ou extr�mes;
PROC SORT DATA = resid2; BY DESCENDING dfb2; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb2 ID VISIT COUNTS COUNTS0 resid; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb2; RUN;

PROC SORT DATA = resid2; BY DESCENDING dfb3; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb3 ID VISIT COUNTS COUNTS0 resid; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb3; RUN;

PROC SORT DATA = resid2; BY DESCENDING dfb5; RUN;
PROC PRINT DATA = resid2 (OBS = 20); VAR dfb5 ID VISIT COUNTS COUNTS0 resid; RUN;
PROC SGPLOT DATA = resid2; NEEDLE X = ID Y = dfb5; RUN;

*Il reste des valeurs un peu influentes, mais ce ne sont pas celles avec les r�sidus les plus grands.;
*� titre d'�tude de sensibilit�, je retire �galement

205 1 
116 1;
DATA resid2;
	SET resid;
	num + 1;
RUN;
PROC SGPLOT DATA = resid2;
	NEEDLE Y = dfbeta3 X = num;
RUN;


PROC SORT DATA = seizure3; BY ID Visit; RUN;
PROC GENMOD DATA = seizure3;
	WHERE NOT ((ID = 207 AND VISIT = 1) OR (ID = 205 AND VISIT = 1) OR (ID = 116 AND VISIT = 1));
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX logC0 / DIST = NORMAL LINK = LOG TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1); 
	LSMEANS TX / DIFF AT VISIT = 1 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 2 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 3 ALPHA = 0.05 EXP;
	LSMEANS TX / DIFF AT VISIT = 4 ALPHA = 0.05 EXP;
RUN; *Les r�sultats sont les m�mes.;

ODS LISTING;
PROC SORT DATA = seizure3; BY ID Visit; RUN;
PROC GENMOD DATA = seizure3;
	WHERE NOT ((ID = 207 AND VISIT = 1) OR (ID = 205 AND VISIT = 1) OR (ID = 116 AND VISIT = 1));
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX counts0 / DIST = NORMAL LINK = ID TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1); 
	LSMEANS TX / DIFF AT VISIT = 1 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 2 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 3 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 4 ALPHA = 0.05;
RUN;
*Les conclusions demeurent toujours les m�mes.
*Je pr�senterais en principal les conclusions du mod�le 
sans transformation avec toutes les observations et je mentionnerais 
les autres analyses effectu�es et que les conclusions demeurent les m�mes avec
la mention (r�sultats non pr�sent�s).;


/*Si j'utilisais plut�t un mod�le de Poisson, les estimations seraient
assez similaires, mais j'aurais beaucoup plus de puissance*/
PROC SORT DATA = seizure3; BY ID Visit; RUN;
PROC GENMOD DATA = seizure3;
	WHERE NOT ((ID = 207 AND VISIT = 1) OR (ID = 205 AND VISIT = 1) OR (ID = 116 AND VISIT = 1));
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX counts0 / DIST = Poisson LINK = ID TYPE3 WALD ALPHA = 0.05;
	REPEATED SUBJECT = ID / TYPE = AR(1); 
	LSMEANS TX / DIFF AT VISIT = 1 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 2 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 3 ALPHA = 0.05;
	LSMEANS TX / DIFF AT VISIT = 4 ALPHA = 0.05;
RUN;

/*
LSMEANS (Diff�rences de moyennes dans les deux cas, car lien ID)
Normal:
-------
TX  _TX   Visit  Counts0  Estimate     Error  z Value  Pr > |z|

1   0      1.00    30.32   -2.6878    1.4752    -1.82    0.0684
1   0      2.00    30.32   -2.1202    1.2922    -1.64    0.1008
1   0      3.00    30.32   -1.5526    1.3142    -1.18    0.2375
1   0      4.00    30.32   -0.9850    1.5325    -0.64    0.5204

Poisson:
--------
1   0      1.00    30.32   -1.9493    0.9673    -2.02    0.0439
1   0      2.00    30.32   -1.6922    0.6942    -2.44    0.0148
1   0      3.00    30.32   -1.4352    0.5865    -2.45    0.0144
1   0      4.00    30.32   -1.1781    0.7226    -1.63    0.1030
*/
