/*Exemple de solution exercice 8.1*/

/*Importation des données*/
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/mscm.csv"
	OUT = mscm
	REPLACE
	DBMS = CSV;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = mscm; RUN;

PROC PRINT DATA = mscm (OBS = 60); RUN;

PROC FREQ DATA = mscm; 
	TABLE id;
RUN;

PROC FREQ DATA = mscm;
	TABLE day;
RUN; /*Il y a bien une ligne par sujet par jour/

*Statistiques descriptives;

/*Statistiques descriptives au baseline*/
PROC MEANS DATA = mscm MIN Q1 MEAN MEDIAN Q3 MAX;
	WHERE day = 8; /*pour faire des statistiques par sujet 
				(une seule ligne par sujet, notez que toutes les lignes
				devraient être identiques en ce qui a trait aux caractéristiques
				au baseline)*/
	VAR bStress;
RUN;

PROC FREQ DATA = mscm;
	WHERE day = 8;
	TABLE bstress;
RUN;

/*Je vais catégoriser l'exposition d'intérêt
pour obtenir des statistiques descriptives
en fonction du niveau d'exposition*/
DATA mscm2;
	SET mscm;
	IF bStress NE . THEN DO;
		IF bStress = 0 THEN bstressCat = "1. bstress = 0             ";
		ELSE IF bstress <= 0.2 THEN bstressCat = "2. 0 < bstress <= 0.2";
		ELSE bstressCAT = "3. bstress > 0.2";
	END;
	IF csex = 2 THEN csex = 0;
RUN;

PROC FREQ DATA = mscm2;
	WHERE day = 8;
	TABLE bstressCAT;
RUN;

PROC SORT DATA = mscm2; BY bstressCat day; RUN;
PROC MEANS DATA = mscm2 NOPRINT;
	BY bstressCat day;
	VAR illness;
	OUTPUT OUT = moyennes MEAN = ;
RUN;

PROC SORT DATA = moyennes; BY bstressCat day; RUN;
PROC SGPLOT DATA = moyennes;
	SERIES X = day Y = illness / GROUP = bstressCat;
	LOESS X = day Y = illness / GROUP = bstressCat NOMARKERS;
	YAXIS MIN = 0 MAX = 0.3;
RUN;
/*Il y a beaucoup de variation dans les moyennes, mais la tendance semble pouvoir être bien approximée de façon linéaire*/

PROC TABULATE DATA = mscm2;
	WHERE day = 8;
	CLASS education chlth mhlth bstressCat;
	VAR married employed race csex housize billness;
	TABLE (billness)*(mean = "moyenne" std = "ét") 
		  (married employed race csex housize)*(sum = "n" * f = f9.0 mean = "%" * f = PERCENT7.3) 
		  (education chlth mhlth)*(n = "n" COLPCTN = "%") n, bstressCat;
RUN;
/*Il faut regrouper ensemble des catégories à faibles fréquences*/

DATA mscm3;
	SET mscm2;
	IF education = 1 THEN education = 2;
	IF education = 5 THEN education = 4;
	IF chlth = 1 OR chlth = 2 THEN chlth = 3;
	IF mhlth = 1 OR mhlth = 2 THEN mhlth = 3;
	/* On en profite pour créer une 2e version de la variable day pour traiter en catégories */
	jour=day;
RUN;

PROC TABULATE DATA = mscm3;
	WHERE day = 8;
	CLASS education chlth mhlth bstressCat;
	VAR married employed race csex housize billness;
	TABLE (billness)*(mean = "moyenne" std = "ét") 
		  (married employed race csex housize)*(sum = "n" * f = f9.0 mean = "%" * f = PERCENT7.3) 
		  (education chlth mhlth)*(n = "n" COLPCTN = "%") n, bstressCat;
RUN;

/*Analyses GEE*/
ODS GRAPHICS ON;
PROC SORT DATA = mscm3; BY id day; RUN;
/* Distribution de travail binomiale, lien log */
PROC GENMOD DATA = mscm3 DESCENDING PLOTS = (DFBETA);
	CLASS chlth mhlth education id jour / PARAM = REF;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness / DIST = binomial LINK = log TYPE3 WALD;
	REPEATED SUBJECT = id / TYPE = un within=jour; 
	OUTPUT OUT = sortie P = predit RESRAW = resid
	DFBETA = _all_;
	/*Puisque day est entré de façon continue,
	la ligne "bstress" du tableau de type 3 ne donne
	pas l'effet "moyen" du stress initial.
	On peut plutôt l'obtenir en déterminant l'effet au temps
	moyen :*/
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP;
RUN; /*Le jour du milieu de suivi est (30 + 8)/2 = 19;*/
/* Estimation du RR à 19 jours (IC à 95%) : 1.62 (0.81 - 3.26) */

PROC GENMOD DATA = mscm3 DESCENDING PLOTS = (DFBETA);
	CLASS chlth mhlth education id jour / PARAM = REF;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness / DIST = binomial LINK = log TYPE3 WALD;
	REPEATED SUBJECT = id / TYPE = ar(1) within=jour; 
	OUTPUT OUT = sortie P = predit RESRAW = resid reschi=presid
	DFBETA = _all_;
	/*Puisque day est entré de façon continue,
	la ligne "bstress" du tableau de type 3 ne donne
	pas l'effet "moyen" du stress initial.
	On peut plutôt l'obtenir en déterminant l'effet au temps
	moyen :*/
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP;
RUN; 

/* Distribution de travail Poisson, lien log */
PROC GENMOD DATA = mscm3 DESCENDING PLOTS = (DFBETA);
	CLASS chlth mhlth education id jour / PARAM = REF;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness / DIST = poisson LINK = log TYPE3 WALD;
	REPEATED SUBJECT = id / TYPE = ar(1) within=jour; 
	OUTPUT OUT = sortie P = predit RESRAW = resid
	DFBETA = _all_;
	/*Puisque day est entré de façon continue,
	la ligne "bstress" du tableau de type 3 ne donne
	pas l'effet "moyen" du stress initial.
	On peut plutôt l'obtenir en déterminant l'effet au temps
	moyen :*/
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP;
RUN; 
PROC GENMOD DATA = mscm3 DESCENDING PLOTS = (DFBETA);
	CLASS chlth mhlth education id jour / PARAM = REF;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness / DIST = poisson LINK = log TYPE3 WALD;
	REPEATED SUBJECT = id / TYPE = UN within=jour; 
	OUTPUT OUT = sortie P = predit RESRAW = resid dfbeta=_all_;	/*Puisque day est entré de façon continue,
	la ligne "bstress" du tableau de type 3 ne donne
	pas l'effet "moyen" du stress initial.
	On peut plutôt l'obtenir en déterminant l'effet au temps
	moyen :*/
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP;
RUN; 
/* Estimation du RR à 19 jours (IC à 95%) : 1.71 (0.85 - 3.44) */


/*J'ai choisi la matrice UN, car c'était celle qui donnait le meilleur critère
QIC. Notez que QIC peut être utilisé pour comparer des modèles variant autant
dans leur partie aléatoire (REPEATED) que dans leur partie fixe lorsque
la distribution de travail n'est pas NORMAL*/
/*IND: QIC = 2904.4745
AR(1): QIC = 2866.1171
CS: QIC = 2904.2119
UN: QIC = 2519.4361 */



/*Vérification des hypothèses*/
/*Dans le graphique des DFBETAs, je vois une ou deux observations potentiellement influentes.
Concernant le DFBETA pour bstress, les valeurs extrêmes ont des valeurs élevées. Je vais donc trier
mes valeurs de DFBeta3 de la plus grande à la plus petite pour repérer cette observation*/
PROC SORT DATA = sortie; BY DESCENDING DFbeta_bstress; RUN;
PROC PRINT DATA = sortie (OBS = 20);
	VAR ID day bstress chlth mhlth education married
		employed race csex housize billness DFBeta_bstress;
RUN;
/*810503 8 0.8333333333 3 3 4 0 0 1 1 0 0.1666666667 0.15325 */

/*Pour le DFBETA bstress*day, les valeurs extrêmes sont négatives. Je vais donc trier
mes valeurs de DFBeta4 de la plus petite à la plus grande.*/
PROC SORT DATA = sortie; BY DFbeta_daybstress; RUN;
PROC PRINT DATA = sortie (OBS = 20);
	WHERE DFBeta_daybstress ne .;
	VAR ID day bstress chlth mhlth education married
		employed race csex housize billness DFBeta_daybstress;
RUN;
/*810503 8 0.8333333333 3 3 4 0 0 1 1 0 0.1666666667 -.007252670 */

/*C'est la même observation qui apparaît influente pour les deux paramètres.*/

/*Multicollinéarité*/	
DATA binaire;
	SET mscm3;
	IF education ne . THEN DO;
		IF education = 2 THEN education_2 = 1; ELSE education_2 = 0;
		IF education = 3 THEN education_3 = 1; ELSE education_3 = 0;
	END;
	IF chlth ne . THEN DO;
		IF chlth = 3 THEN chlth_3 = 1; ELSE chlth_3 = 0;
		IF chlth = 4 THEN chlth_4 = 1; ELSE chlth_4 = 0;
	END;
	IF mhlth ne . THEN DO;
		IF mhlth = 3 THEN mhlth_3 = 1; ELSE mhlth_3 = 0;
		IF mhlth = 4 THEN mhlth_4 = 1; ELSE mhlth_4 = 0;
	END;
	dayXbstress = day*bstress;
RUN;

ODS GRAPHICS OFF;
PROC REG DATA = binaire;
	MODEL illness = bstress day dayXbstress
					chlth_3 chlth_4 mhlth_3 mhlth_4 education_2 education_3
					married employed race csex housize billness / VIF;
RUN; QUIT;
/*ok sauf pour exposition et interaction - c'est un peu attendu qu'il y ait
de la collinéarité entre l'exposition et l'interaction et on ne peut rien
y faire.*/

/*Linéarité*/
PROC SGPLOT DATA = sortie;
	LOESS X = day Y = resid;
	REFLINE 0;
RUN;
PROC SGPLOT DATA = sortie;
	LOESS X = day Y = presid;
	REFLINE 0;
RUN;
PROC SGPLOT DATA = sortie;
	LOESS X = bstress Y = resid;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	LOESS X = bstress Y = presid / smooth=0.5;
	REFLINE 0;
RUN;
PROC SGPLOT DATA = sortie;
	LOESS X = billness Y = resid;
	REFLINE 0;
RUN;
PROC SGPLOT DATA = sortie;
	LOESS X = billness Y = presid / smooth=0.5;
	REFLINE 0;
RUN;
/*ok*/

/*Je refais le modèle sans l'observation potentiellement influente.*/
ODS GRAPHICS ON;
PROC SORT DATA = mscm3; BY id day; RUN;
PROC GENMOD DATA = mscm3 DESCENDING PLOTS = (DFBETA);
	WHERE NOT(id = 810503 AND day = 8);
	CLASS chlth mhlth education id / PARAM = REF;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness / DIST = binomial LINK = log TYPE3 WALD;
	REPEATED SUBJECT = id / TYPE = UN; 
	OUTPUT OUT = sortie P = predit RESRAW = resid 
	DFBETA = _all_;
 	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP;
RUN; /*Les conclusions vont dans la même direction. 
Les graphiques suggèrent qu'il pourrait rester des observations influentes...
On pourrait continuer le processus, c'est-à-dire repérer la prochaine observation
la plus influente et la retirer en guise d'analyse de sensibilité et vérifier si
les conclusions sont modifiées.*/

/*Conclusion (avec toutes obs) : 
Nos données ne permettent pas de rejeter l'hypothèse que l'association entre
le stress maternel initial et le risque que l'enfant soit malade ne varie pas dans
le mois suivant (p de l'interaction = 0.61). Un stress maternel initial plus élevé
est associé dans nos données à un risque plus important que l'enfant soit malade dans
les jours du mois suivant, mais la puissance insuffisante ne
permet pas de conclure concernant l'association réelle dans la population
RR = 1.46 IC à 95%: (0.68 - 3.12). */


/*Exemple de solution exercice 8.2*/

PROC SORT DATA = mscm3; BY id day; RUN;
/* MV par approximation de Laplace avec ordonnée à l'origine aléatoire, lien logit */ 
PROC GLIMMIX DATA = mscm3 method=laplace;
	CLASS chlth mhlth education id;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness 
		/ DIST = binomial LINK = logit SOLUTION CL;
	RANDOM intercept / SUBJECT = id; 
	OUTPUT OUT = sortie STUDENT = resid PRED = predit;
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP CL;
RUN; 
/* Estimation du RC à 19 jours (IC à 95%) : 1.59 (0.62 - 4.05) */

/* MV par approximation de Laplace avec ordonnée à l'origine aléatoire, lien log */ 
PROC GLIMMIX DATA = mscm3 method=laplace;
	CLASS chlth mhlth education id;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness 
		/ DIST = binomial LINK = log SOLUTION CL;
	RANDOM intercept / SUBJECT = id; 
	OUTPUT OUT = sortie STUDENT = resid PEARSON(ILINK) = presid PRED = predit;
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP CL;
RUN; 
/* Estimation du RR à 19 jours (IC à 95%) : 1.58 (0.74 - 3.35) */

/* MV par approximation de Laplace avec ordonnée à l'origine et pente aléatoire, lien logit */ 
PROC GLIMMIX DATA = mscm3 method=laplace;
	CLASS chlth mhlth education id;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness 
		/ DIST = binomial LINK = logit SOLUTION CL;
	RANDOM intercept day / SUBJECT = id type=un; 
	OUTPUT OUT = sortie STUDENT = resid PEARSON(ILINK) = presid PRED = predit;
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP CL;
RUN; 
/* Estimation du RC à 19 jours (IC à 95%) : 1.72 (0.61 - 4.89) */

/* MV par approximation de Laplace avec ordonnée à l'origine et pente aléatoire, lien log: ne converge pas */ 


/* Maximum d'une pseudo vraisemblance, lien logit */
PROC GLIMMIX DATA = mscm3 INFOCRIT = PQ;
	CLASS chlth mhlth education id jour;
	MODEL illness = day|bstress chlth mhlth education married
					employed race csex housize billness 
		/ DIST = binomial LINK = logit DDFM = KR SOLUTION CL;
	/* Formulation proposée dans les notes de cours. 
	En principe, fonctionne seulement si les données sont complètes. */
	*RANDOM _residual_ / SUBJECT = id TYPE = AR(1); 
	/* Quand les données sont incomplètes, il faut préciser la variable qui indique le temps d'observation */
	RANDOM jour / SUBJECT = id TYPE = AR(1) residual; 
	OUTPUT OUT = sortie STUDENT = resid PEARSON(ILINK) = presid PRED = predit;
	ESTIMATE "bstress au jour 19" bstress 1 bstress*day 19 / EXP CL;
RUN; 
/* Estimation du RC à 19 jours (IC à 95%) : 1.57 (0.68 - 3.65) */

/*
Choix de la matrice :
VC: BIC = 18394.31 
CS: BIC =  18287.21 
AR(1): BIC = 17790.36
UN: Trop long à exécuter...
ARH(1): Ne converge pas...
J'oublie donc les matrices hétérogènes
TOEP: Ne converge pas...
ANTE(1): Ne converge pas...

Je choisis AR(1)...
*/

/*Je ne revérifie pas les VIFs, fait en exercice 8.1*/

PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = resid;
	LOESS X = predit Y = resid;
	REFLINE 0;
RUN;
PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = presid;
	LOESS X = predit Y = presid;
	REFLINE 0;
RUN;
/*On n'est incapable de détecter des données influentes simplement avec ce graphique
(en tout cas, moi je ne pourrais pas)*/

PROC SGPLOT DATA = sortie;
	LOESS X = day Y = resid;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	LOESS X = bstress Y = resid;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	LOESS X = bstress Y = presid;
	REFLINE 0;
RUN;
PROC SGPLOT DATA = sortie;
	LOESS X = billness Y = resid;
	REFLINE 0;
RUN; /*ok*/

/*Les conclusions vont dans la même direction qu'avec les GEEs*/
