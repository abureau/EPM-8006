*On construit un mod�le pour d�terminer l'effet de la consommation de lait
sur le risque de fracture de la hanche;
/*Plus pr�cis�ment, je vais consid�rer comme exposition la variable 
BDQ229 : Consommation de lait r�guli�re 5 fois par semaine	
1= consommateur r�gulier de lait toute ma vie ou presque, y compris en enfance; 
2= jamais �t� consommateur r�gulier de lait; 
3= ma consommation de lait a vari� au cours de ma vie � 
j�ai parfois �t� consommateur r�gulier de lait;

et comme r�ponse OSQ010A (fracture de la hanche 1 = oui, 2 = non)

Nous estimerons un effet conditionnel
avec une approche bay�sienne.

Puisque le probl�me est tr�s similaire � celui consid�r� pour la r�gression lin�aire,
je consid�rerai les m�mes facteurs potentiellement confondants.*/

*J'importe le fichier osteo5 nettoy�.;
PROC IMPORT DATAFILE = "C:\Users\etudiant\Documents\EPM-8006\donnees\osteo5.csv"
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

/* Approche des pseudo-donn�es */

/* Pseudo-donn�es pour coefficients de cons_reg et cons_var
   On donne la valeur 1 pour les variables cat�goriques car c'est la valeur de r�f�rence
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
/* Ajout des variables strate et poids au jeu de donn�es ost�o */
  strate = 1;
  poids = 1;
  /* Centrage de l'�ge, du BMI, du poids actuel et du poids il y a 10 ans */
  RIDAGEYR = RIDAGEYR - 50;
  BMXBMI = BMXBMI - 29;
  WHD020 = WHD020 - 177;
  WHD110 = WHD110 - 170;
run;

/* Ajout des pseudo donn�es � la base de donn�es */
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
TITLE "Mod�le avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = JEFFREYS 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 10 /*On garde 1/10*/
		  NMC = 10000 /*Nombre d'it�rations apr�s les burn-in*/
		  PLOTS = ALL; 
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;
*Il semble y avoir une forte auto-corr�lation, 1/10 n'est probablement pas assez.;


*Beaucoup plus long, mais les r�sultats sont plus coh�rents avec les r�sultats du MV (maximum de vraisemblance);
ODS GRAPHICS ON;
TITLE "Mod�le avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = JEFFREYS 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 100 /*On garde 1/100*/
		  NMC = 100000 /*Nombre d'it�rations apr�s les burn-in, on fait 10x plus d'it�rations pour garder
		  le m�me nombre d'�chantillon.*/
		  PLOTS(LAGS = 100) = ALL; /*Jusqu'� quoi tracer le graphique d'auto-corr�lation*/ 
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;


TITLE "Mod�le avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = UNIFORM /*L'estimation �choue, relativement courant avec les lois impropres*/
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 100 /*On garde 1/10*/
		  NMC = 100000 /*Nombre d'it�rations apr�s les burn-in*/
		  PLOTS(LAGS = 100) = ALL;
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;

/*D�finition de la loi a priori,
je la prends informative, � titre d'exemple,
pour les param�tres associ�s � la consommatin de lait*/
DATA prior;
   INPUT _type_ $ Intercept cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH11 RIDRETH12 RIDRETH13 RIDRETH14 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110;
   datalines;
Var  1e6 1 1 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6 1e6
Mean 0.0 -1.389 -0.693 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
;
RUN;


TITLE "Mod�le avec ajustement 2";
PROC GENMOD DATA = osteo;
	BAYES COEFFPRIOR = NORMAL (INPUT = prior) 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 100 /*On garde 1/100*/
		  NMC = 100000 /*Nombre d'it�rations apr�s les burn-in*/
		  PLOTS(LAGS = 100) = ALL;
	CLASS OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 ALQ101 MCQ160C MCQ160L /PARAM = GLM; *PARAM = GLM pour notre codification habituelle des effets;
	MODEL  OSQ010A = cons_reg cons_var  OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
				ALQ101 ALQ130 BMXBMI MCQ160C MCQ160L WHD020 WHD110 / DIST = binomial LINK = logit;
RUN;
/*1/100 semble fortement insuffisant en regardant les graphiques d'auto-corr�lations
Les diagnostiques de Geweke semblent aussi indiquer que le nombre de burn-in est insuffisant. 
On n'essaiera pas de corriger en laboratoire, car le programme deviendrait certainement beaucoup trop long!*/
