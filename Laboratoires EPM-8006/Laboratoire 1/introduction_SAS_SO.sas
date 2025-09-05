/* === Importation des données === */

/* Méthode 1 : PROC IMPORT (rapide, mais moins de contrôle) */
PROC IMPORT DATAFILE = "/workspaces/workspace/EPM-8006/Laboratoires EPM-8006/Laboratoire 1/fram1.csv" 
    OUT = fram1
    REPLACE
    DBMS = CSV;
RUN;

/* Méthode 2 : DATA step (plus de contrôle, nécessite connaître la structure du fichier) */
DATA fram2;
  infile "/workspaces/workspace/EPM-8006/Laboratoires EPM-8006/Laboratoire 1/fram1.csv" dlm=',' dsd firstobs=2;
  input id age sex $ sysbp diabp;
run;

/* Vérifier que l'importation est correcte */
PROC CONTENTS DATA = fram1 VARNUM; RUN;

/* Aperçu des premières lignes */
PROC PRINT DATA = fram1 (OBS = 10); RUN;

/* Questions: Différences entre les deux méthodes ? Avantages/inconvénients ? */

/* Statistiques descriptives globales */
PROC MEANS DATA = fram1 MIN Q1 MEAN MEDIAN Q3 MAX STD maxdec=2;
    VAR age sysbp diabp bmi CIGPDAY;
RUN;

/* Visualiser SYSBP*/
/* Ajouter un identifiant d'observation pour repérer les valeurs extrêmes */
data fram1_indexed;
  set fram1;
  obs_id = _N_;  /* _N_ = numéro de ligne */
run;

/* Visualiser SYSBP pour détecter les valeurs extrêmes */
proc sgplot data=fram1_indexed;
  scatter x=obs_id y=SYSBP;
  title "SYSBP par observation";
run;
*On remarque des valeurs douteuses pour la SBP (pression systolique) ;

/* Statistiques descriptives pour variables qualitatives */
PROC FREQ DATA = fram1;
    TABLE sex cursmoke diabetes;
RUN;

/* Afficher les lignes avec SYSBP très élevé */
PROC PRINT DATA = fram1;
    WHERE SYSBP >= 290;
    VAR RANDID SYSBP;
RUN;

/* Supprimer observation extrême (deux méthodes) */
DATA fram1b;
    SET fram1;
    IF RANDID in (1080920) THEN DELETE;
RUN;

/*  Méthode 2 : */
DATA fram1b;
    SET fram1;
    IF SYSBP >= 290 THEN DELETE;
RUN;

/* Vérification:*/
proc contents data=fram1b;
run;

/* Statistiques descriptives séparées par sexe */
PROC SORT DATA = fram1b; BY sex; RUN;
PROC MEANS DATA = fram1b MIN Q1 MEAN MEDIAN Q3 MAX STD maxdec=2;
    BY sex;
    VAR age sysbp diabp bmi CIGPDAY;
RUN;

/* Créer une variable hypertension (SBP > 140 ou DBP > 90) */
DATA fram1c;
    SET fram1b;
    IF (SYSBP ne . AND SYSBP > 140) or (DIABP ne . AND DIABP > 90) THEN hypertension = 1;
    ELSE IF (SYSBP ne . AND SYSBP < 140) or (DIABP ne . AND DIABP < 90) THEN hypertension = 0;
RUN;
/* Limites ? (ex. si une mesure est manquante) */

/* Version plus robuste : gère les valeurs manquantes correctement */
DATA fram1c;
  SET fram1b;
  if (not missing(SYSBP) and SYSBP >= 140) 
     or (not missing(DIABP) and DIABP >= 90) then hypertension = 1;
  else if ( (not missing(SYSBP) and SYSBP < 140) 
         or (not missing(DIABP) and DIABP < 90) ) then hypertension = 0;
  else hypertension = .;  /* indéterminé */
RUN;

/* Statistiques descriptives chez les hypertendus */
PROC MEANS DATA = fram1c MIN Q1 MEAN MEDIAN Q3 MAX STD maxdec=2;
    WHERE hypertension = 1;
    VAR age sysbp diabp bmi CIGPDAY;
RUN;

/* Lecture d'un fichier permanent avec LIBNAME */
LIBNAME lib "/workspaces/workspace/EPM-8006/Laboratoires EPM-8006/Laboratoire 1";

/* Statistiques descriptives sur données permanentes */
PROC MEANS DATA = lib.frmgham2 MIN Q1 MEAN MEDIAN Q3 MAX STD;
    VAR age sysbp diabp bmi CIGPDAY;
RUN;

/* Créer une nouvelle base permanente */
DATA lib.fram_ex;
    SET fram1c;
RUN;

/* Exemple simple : création d'une table en DATA step */
DATA FAMILLE;
    INPUT ID NOM $ TAILLE REVENU;
    DATALINES;
1 ALICE 4 100
2 BOB 5 100
;
RUN;

PROC PRINT DATA=FAMILLE;
    TITLE "AFFICHAGE DE LA TABLE";
RUN;

PROC contents DATA=FAMILLE;
RUN;

/* Exercice : enregistrer Famille dans votre lib */