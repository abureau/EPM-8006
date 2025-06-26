/*******Solution exercice 6.1*******/

/*Importation des données*/

PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2015\Données\fram1.csv"
	OUT = fram1
	DBMS = CSV
	REPLACE;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 20); RUN;

/*On effectuerait dans une véritable analyse quelques
statistiques descriptives*/

PROC GENMOD DATA = fram1 DESCENDING;
	BAYES COEFFPRIOR = JEFFREYS 
		  NBI = 1000 /*Nombre de Burn-in*/
		  THINNING = 10 /*On garde 1/10*/
		  NMC = 10000 /*Nombre d'itérations après les burn-in*/
		  PLOTS = ALL; 
	MODEL diabetes = cursmoke sex age sysbp bmi cursmoke*bmi / CL DIST = binomial LINK = logit;
RUN;

/*Pour PROC GENMOD, les graphiques de trace commencent après le burn-in.
Sur les graphiques de trace, on ne constate aucune tendance particulière.
Le paramètre de burn-in semble donc suffisant.

Les graphiques d'auto-corrélation n'incluent pas d'intervalles de confiance.
On constate tout de même que l'auto-corrélation se rapproche toujours très 
rapidement de 0. Il ne semble donc pas y avoir de problème à garder 1/10.

Le nombre d'échantillons conservé est de 10 000/10 = 1000, ce qui est suffisant.

Les paramètres de l'algorithme semblent donc appropriés*/
