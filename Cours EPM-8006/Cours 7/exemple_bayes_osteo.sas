*On construit un modèle pour déterminer l'effet de la consommation de lait
sur le risque de fracture de la hanche;
/*Plus précisément, je vais considérer comme exposition la variable 
BDQ229 : Consommation de lait régulière 5 fois par semaine	
1= consommateur régulier de lait toute ma vie ou presque, y compris en enfance; 
2= jamais été consommateur régulier de lait; 
3= ma consommation de lait a varié au cours de ma vie – 
j’ai parfois été consommateur régulier de lait;

et comme réponse OSQ010A (fracture de la hanche 1 = oui, 2 = non)

Nous estimerons un effet conditionnel
avec une approche bayésienne.

Puisque le problème est très similaire à celui considéré pour la régression linéaire,
je considérerai les mêmes facteurs potentiellement confondants.*/

*J'importe le fichier osteo5 nettoyé.;
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/osteo5.csv"
	OUT = osteo
	DBMS = CSV
	REPLACE;
RUN;

proc freq data=osteo;
table alq130*alq101;
run;

/* Remplissage et correction des valeurs de alq130 en supposant que alq101 est correct*/
data osteo;
set osteo;
if alq101 = 2 then alq130 = 0;
run;

/* Approche des pseudo-données */

/* Pseudo-données pour coefficients de cons_reg et cons_var
   On donne la valeur 1 pour les variables catégoriques car c'est la valeur de référence
   On donne la valeur 0 aux variables quantitatives car on va les centrer*/
data osteo_pseudo;
  input seqn  OSQ010A cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 strate poids;
  cards;
  1 1 1 0 1 1 1 1 1 0 1 0 0 1 1 0 0 2 2
  2 1 0 0 1 1 1 1 1 0 1 0 0 1 1 0 0 2 2
  3 2 1 0 1 1 1 1 1 0 1 0 0 1 1 0 0 2 400000
  4 2 0 0 1 1 1 1 1 0 1 0 0 1 1 0 0 2 100000
  5 1 0 1 1 1 1 1 1 0 1 0 0 1 1 0 0 3 2
  6 1 0 0 1 1 1 1 1 0 1 0 0 1 1 0 0 3 2
  7 2 0 1 1 1 1 1 1 0 1 0 0 1 1 0 0 3 200000
  8 2 0 0 1 1 1 1 1 0 1 0 0 1 1 0 0 3 100000
;
run;

proc means data=osteo;
var BMXBMI WHD020 WHD110 RIDAGEYR;
run;

data osteo2;
  set osteo;
/* Ajout des variables strate et poids au jeu de données ostéo */
  strate = 1;
  poids = 1;
  /* Centrage de l'âge, du BMI, du poids actuel et du poids il y a 10 ans */
  RIDAGEYR = RIDAGEYR - 50;
  BMXBMI = BMXBMI - 29;
  WHD020 = WHD020 - 177;
  WHD110 = WHD110 - 170;
run;

/* Ajout des pseudo données à la base de données */
data osteo_aug;
  set osteo2 osteo_pseudo;
run;

proc logistic data=osteo_aug;
class strate(ref="1") OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1(ref="1") ALQ101 MCQ160C MCQ160L / param=ref;
MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 strate / corrb;
freq poids;
run;

ODS GRAPHICS ON;
TITLE "Modèle avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = JEFFREYS 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 10 /*On garde 1/10*/
		  NMC = 10000 /*Nombre d'itérations après les burn-in*/
		  PLOTS = ALL; 
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;
*Il semble y avoir une forte auto-corrélation, 1/10 n'est probablement pas assez.;


*Beaucoup plus long, mais les résultats sont plus cohérents avec les résultats du MV (maximum de vraisemblance);
ODS GRAPHICS ON;
TITLE "Modèle avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = JEFFREYS 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 100 /*On garde 1/100*/
		  NMC = 100000 /*Nombre d'itérations après les burn-in, on fait 10x plus d'itérations pour garder
		  le même nombre d'échantillon.*/
		  PLOTS(LAGS = 100) = ALL; /*Jusqu'à quoi tracer le graphique d'auto-corrélation*/ 
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;


TITLE "Modèle avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = UNIFORM /*L'estimation échoue, relativement courant avec les lois impropres*/
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 100 /*On garde 1/10*/
		  NMC = 100000 /*Nombre d'itérations après les burn-in*/
		  PLOTS(LAGS = 100) = ALL;
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;

/*Définition de la loi a priori,
je la prends informative, à titre d'exemple,
pour les paramètres associés à la consommatin de lait*/
DATA prior;
   INPUT _type_ $ Intercept cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH11 RIDRETH12 RIDRETH13 RIDRETH14 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110;
   datalines;
Var  1e6 1 1 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6
Mean 0.0 -1.389 -0.693 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
;
RUN;


TITLE "Modèle avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = NORMAL (INPUT = prior) 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 100 /*On garde 1/100*/
		  NMC = 100000 /*Nombre d'itérations après les burn-in*/
		  PLOTS(LAGS = 100) = ALL;
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;
/*1/100 semble fortement insuffisant en regardant les graphiques d'auto-corrélations
Les diagnostiques de Geweke semblent aussi indiquer que le nombre de burn-in est insuffisant. 
On n'essaiera pas de corriger en laboratoire, car le programme deviendrait certainement beaucoup trop long!*/
