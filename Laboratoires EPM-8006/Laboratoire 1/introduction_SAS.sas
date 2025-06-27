/*Exemple d'importation des données avec PROC IMPORT*/
PROC IMPORT DATAFILE = "F:\fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 10); RUN;

/*Exemple d'utilisation de l'assistant d'importation*/


/*Quelques statistiques descriptives*/
PROC MEANS DATA = fram1 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;
*On remarque des valeurs douteuses pour la SBP;

PROC FREQ DATA = fram1;
	TABLE sex cursmoke diabetes;
RUN;

/*Afficher la ou les lignes avec des valeurs très élevées de SBP*/

PROC PRINT DATA = fram1;
	WHERE SYSBP > 290;
	VAR RANDID SYSBP;
RUN;

/*Supprimer l'observation avec une valeur extrême*/
DATA fram1b;
	SET fram1;
	IF RANDID in (1080920) THEN DELETE;
RUN;


/*Effectuer des statistiques descriptives séparément chez les hommes et chez les femmes*/
PROC SORT DATA = fram1b; BY sex; RUN;
PROC MEANS DATA = fram1b MIN Q1 MEAN MEDIAN Q3 MAX STD;
	BY sex;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;


/*Créer une variable pour hypertension SBP > 140 ou DBP > 90*/
DATA fram1c;
	SET fram1b;
	IF (SYSBP ne . AND SYSBP > 140) or (DIABP ne . AND DIABP > 90) THEN hypertension = 1;
	ELSE IF (SYSBP ne . AND SYSBP < 140) or (DIABP ne . AND DIABP < 90) THEN hypertension = 0;
RUN;

/*Regarder des statistiques descriptives seulement chez les personnes souffrant
d'hypertension*/
PROC MEANS DATA = fram1c MIN Q1 MEAN MEDIAN Q3 MAX STD;
	WHERE hypertension = 1;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;

/*Lecture de fichier permanent avec libname*/
LIBNAME lib "F:\";

/*utiliser l'explorateur pour regarder les données*/

/*Afficher des statistiques descriptives sur ces données permanentes*/
PROC MEANS DATA = lib.frmgham2 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;

/*Créer une nouvelle base permanente*/
DATA lib.fram_ex;
	SET fram1c;
RUN;
