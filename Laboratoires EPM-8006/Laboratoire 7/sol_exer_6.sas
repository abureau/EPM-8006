/*******Solution exercice 6.1*******/

/*Importation des donn�es*/

PROC IMPORT DATAFILE = "C:\Users\userlogonclasses\Documents\EPM-8006\donnees\fram1.csv"
	OUT = fram1
	DBMS = CSV
	REPLACE;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 20); RUN;

/*On effectuerait dans une v�ritable analyse quelques
statistiques descriptives*/

/* a priori informatif sur tabagisme et interaction avec BMI */
data priori;
input _type_ $ Intercept cursmoke sex age sysbp bmi cursmoke_bmi;
   datalines;
Var  1e6 0.5 1e6 1e6 1e6 1e6 0.5
Mean 0 0.693 0 0 0 0 0.1
;
run;

DATA fram1;
set fram1;
cursmoke_bmi = cursmoke*bmi;
run;

PROC GENMOD DATA = fram1 DESCENDING;
	BAYES COEFFPRIOR = normal(input=priori) 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 10 /*On garde 1/10*/
		  NMC = 10000 /*Nombre d'it�rations apr�s les burn-in*/
		  PLOTS = ALL; 
	MODEL diabetes = cursmoke sex age sysbp bmi cursmoke_bmi / CL DIST = binomial LINK = logit;
RUN;

PROC GENMOD DATA = fram1 DESCENDING;
	BAYES COEFFPRIOR = jeffreys 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 10 /*On garde 1/10*/
		  NMC = 10000 /*Nombre d'it�rations apr�s les burn-in*/
		  PLOTS = ALL; 
	MODEL diabetes = cursmoke sex age sysbp bmi cursmoke_bmi / CL DIST = binomial LINK = logit;
RUN;
/*Pour PROC GENMOD, les graphiques de trace commencent apr�s le burn-in.
Sur les graphiques de trace, on ne constate aucune tendance particuli�re.
Le param�tre de burn-in semble donc suffisant.

Les graphiques d'auto-corr�lation n'incluent pas d'intervalles de confiance.
On constate tout de m�me que l'auto-corr�lation se rapproche toujours tr�s 
rapidement de 0. Il ne semble donc pas y avoir de probl�me � garder 1/10.

Le nombre d'�chantillons conserv� est de 10 000/10 = 1000, ce qui est suffisant.

Les param�tres de l'algorithme semblent donc appropri�s*/
