ODS HTML CLOSE;
ODS HTML;
ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des données*/
PROC IMPORT DATAFILE = "C:\Users\etudiant\Documents\EPM-8006\donnees\fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

DATA fram1b;
	SET fram1;
	cursmokeXsex = cursmoke*sex;
RUN;

PROC MEANS DATA = fram1b N SUM;
	CLASS sex cursmoke;
	VAR diabetes;
RUN;

PROC GENMOD DATA = fram1b;
	CLASS RANDID;
	MODEL diabetes = cursmoke sex cursmokeXsex age bmi SYSBP DIABP / DIST = poisson LINK = log COVB;
	REPEATED SUBJECT = RANDID;
	ESTIMATE "Femme fum vs femme non fum" cursmoke 1;
	ESTIMATE "homme non fum vs femme non fum" sex 1;
	ESTIMATE "homme fum vs femme non fum" sex 1 cursmoke 1 cursmokeXsex 1;
	ESTIMATE "homme fum vs homme non fum" cursmoke 1 cursmokeXsex 1;
	ESTIMATE "RRR" cursmokeXsex 1;
RUN; QUIT;


