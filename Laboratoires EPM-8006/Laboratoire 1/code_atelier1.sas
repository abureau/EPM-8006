/*EPM-8006: Concepts avanc�s en mod�lisation statistique I
Professeur: Alexandre Bureau
Auxiliaire d'enseignement: Lo�c Mangnier

Code SAS pour le laboratoire 1 d'introduction � R et � SAS
Objectifs:
� la fin de cet atelier, l'�tudiant sera:
  -Familier avec SAS et son logiciel (console + �diteur)
  -Capable de d�finir un r�pertoire de travail et importer des donn�es sous format texte (.csv, .txt, .tsv, etc...)
  -Capable de proc�der � des �tapes simples de pr�traitement, de filtres et de statistiques descriptives � travers diff�rentes proc�dures*/


/*Exemple d'importation des donn�es avec PROC IMPORT*/
/*Il convient de changer les chemins d'acc�s*/
PROC IMPORT DATAFILE = "D:\EPM-8006\Laboratoires\Introduction-SAS-R\data\fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = fram1 VARNUM; RUN; /*�quivalent � la fonction str de R*/

PROC PRINT DATA = fram1 (OBS=10); RUN; /*On affiche les 10 premi�res lignes du fichier de donn�es*/

/*Exemple d'utilisation de l'assistant d'importation*/


/*Quelques statistiques descriptives*/
PROC MEANS DATA = fram1 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;
*On remarque des valeurs douteuses pour la SBP;

PROC FREQ DATA = fram1;
	TABLE sex cursmoke diabetes;
RUN;

/*Afficher la ou les lignes avec des valeurs tr�s �lev�es de SBP*/

PROC PRINT DATA = fram1;
	WHERE SYSBP > 290;
	VAR RANDID;
RUN;

/*Supprimer l'observation avec une valeur extr�me*/
DATA fram1b;
	SET fram1;
	IF RANDID in (1080920) THEN DELETE;
RUN;

/* Si l'on veut supprimer les lignes avec des valeurs sup�rieures � une valeur seuil donn�e*/
DATA fram1b;
	SET fram1;
	IF SYSBP > 290 THEN DELETE;
RUN;

/* Exercice: Supprimer les hommes pour lesquels on observe une pression systolique > 290 et une pression diastolique > 45*/


/*Effectuer des statistiques descriptives s�par�ment chez les hommes et chez les femmes*/
PROC SORT DATA = fram1b; BY sex; RUN;
PROC MEANS DATA = fram1b MIN Q1 MEAN MEDIAN Q3 MAX STD;
	BY sex;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;


/*Cr�er une variable pour hypertension SBP > 140 ou DBP > 90*/
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
LIBNAME lib "D:\EPM-8006\Laboratoires\Introduction-SAS-R\data";

/*utiliser l'explorateur pour regarder les donn�es*/

/*Afficher des statistiques descriptives sur ces donn�es permanentes*/
PROC MEANS DATA = lib.fram1 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;

/*Cr�er une nouvelle base permanente*/
DATA lib.fram_ex;
	SET fram1c;
RUN;
