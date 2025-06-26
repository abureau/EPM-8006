/*******Solution exercice 4.5*******/

/*Importation des donn�es*/

PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2015\Donn�es\fram1.csv"
	OUT = fram1
	DBMS = CSV
	REPLACE;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 20); RUN;

/*On effectuerait dans une v�ritable analyse quelques
statistiques descriptives*/

PROC LOGISTIC DATA = fram1 DESCENDING;
/*A*/MODEL diabetes = cursmoke sex age sysbp bmi cursmoke*bmi / CL;
/*B*/CONTRAST "effet fumeur" cursmoke 1, cursmoke*bmi 1;
/*C*/ESTIMATE "RC fumeur vs n-fumeur IMC = 25" cursmoke 1 cursmoke*bmi 25 / CL EXP; 
/*RC = 0.69, IC = 0.44 � 1.09*/
RUN;

/*******Solution exercice 4.7*******/

PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2015\Donn�es\lowbwtm11.xls"
	OUT = lowbw
	DBMS = XLS
	REPLACE;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = lowbw VARNUM; RUN;

PROC PRINT DATA = lowbw (OBS = 20); RUN;

/*Normallement, on ferait quelques statistiques descriptives*/

/*Il s'agit d'un jeu de donn�es provenant d'une �tude 
cas-t�moin appari�e, on devra utiliser une r�gression logistique conditionnelle*/
PROC LOGISTIC DATA = lowbw DESCENDING;
	CLASS low race pair / PARAM = REF; /*par d�faut, la param�trisation
	utilis�e par PROC LOGISTIC est �trange.*/
	MODEL low = smoke race age / CL;
	STRATA pair;
	/*L'�nonc� STRATA permet d'effectuer une r�gression logistique conditionnelle.*/
RUN;
/*RC = 3.711 IC � 95%: 1.397 9.858,
le tabagisme est associ� � une augmentation du risque
de faible poids � la naissance*/





