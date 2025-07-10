/*******Solution exercice 4.5*******/

/*Importation des données*/

PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/fram1.csv"
	OUT = fram1
	DBMS = CSV
	REPLACE;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 20); RUN;

/*On effectuerait dans une véritable analyse quelques
statistiques descriptives*/

PROC LOGISTIC DATA = fram1 DESCENDING;
/*A*/MODEL diabetes = cursmoke sex age sysbp bmi cursmoke*bmi / CL;
/*B*/CONTRAST "effet fumeur" cursmoke 1, cursmoke*bmi 1;
/*C*/ESTIMATE "RC fumeur vs n-fumeur IMC = 25" cursmoke 1 cursmoke*bmi 25 / CL EXP; 
/*RC = 0.69, IC = 0.44 à 1.09*/
RUN;

/*******Solution exercice 4.7*******/

PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/lowbwtm11.xls"
	OUT = lowbw
	DBMS = XLS
	REPLACE;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = lowbw VARNUM; RUN;

PROC PRINT DATA = lowbw (OBS = 20); RUN;

/*Normallement, on ferait quelques statistiques descriptives*/

/*Il s'agit d'un jeu de données provenant d'une étude 
cas-témoin appariée, on devra utiliser une régression logistique conditionnelle*/
PROC LOGISTIC DATA = lowbw DESCENDING;
	CLASS low race pair / PARAM = REF; /*par défaut, la paramétrisation
	utilisée par PROC LOGISTIC est étrange.*/
	MODEL low = smoke race age / CL;
	STRATA pair;
	/*L'énoncé STRATA permet d'effectuer une régression logistique conditionnelle.*/
RUN;
/*RC = 3.711 IC à 95%: 1.397 9.858,
le tabagisme est associé à une augmentation du risque
de faible poids à la naissance*/





