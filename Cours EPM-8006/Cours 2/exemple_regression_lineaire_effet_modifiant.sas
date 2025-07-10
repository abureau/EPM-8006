ODS HTML CLOSE;
ODS HTML;
ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des données*/
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

DATA fram1b;
	SET fram1;
	cursmokeXsex = cursmoke*sex;
RUN;

PROC MEANS DATA = fram1b;
	CLASS sex cursmoke;
	VAR SYSBP;
RUN;

PROC GLM DATA = fram1b;
	MODEL SYSBP = cursmoke sex cursmokeXsex age bmi diabetes / SOLUTION CLPARM;
	ESTIMATE "Homme fumeur vs femme non fumeur" cursmoke 1 sex 1 cursmokeXsex 1;
	ESTIMATE "Homme fumeur vs homme non fumeur" cursmoke 1 cursmokeXsex 1;
RUN; QUIT;
