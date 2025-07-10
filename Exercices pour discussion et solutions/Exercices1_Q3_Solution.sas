/*Importation des données*/
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/lalonde.csv"
	OUT = lalonde
	REPLACE
	DBMS = CSV;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = lalonde VARNUM; RUN;

/*Je calcule des statistiques descriptives selon
l'exposition. Je constate des valeurs extrêmes pour le revenu.*/
PROC MEANS DATA = lalonde MEAN STD SUM MIN Q1 MEDIAN Q3 MAX;
	CLASS treat;
	VAR age educ black hispan married nodegree re74 re75 re78;
RUN;

/*J'ajoute un identifiant et je crée une variable
d'interaction pour PROC REG*/
DATA lalonde2;
	SET lalonde;
	treatXre74 = treat*re74;
	ID + 1;
RUN;

/*J'ajuste le modèle de régression linéaire et je vérifie les hypothèses*/
PROC REG DATA = lalonde2 PLOTS = NONE;
	MODEL re78 = treat treatXre74 age educ black hispan married nodegree re74 re75 / VIF;
	OUTPUT OUT = sortie P = predit STUDENT = student;
RUN; QUIT;


/*1. Linéarité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = age Y = student;
	LOESS X = age Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = educ Y = student;
	LOESS X = educ Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = re74 Y = student;
	LOESS X = re74 Y = student;
	REFLINE 0;
RUN; /*Il semble y avoir une tendance résiduelle, mais 
probablement en raison d'une valeur extrême.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = re75 Y = student;
	LOESS X = re75 Y = student;
	REFLINE 0;
RUN;

/*2. Indépendance - ok selon nos connaissances*/

/*3. Homoscédasticité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = black Y = student;
	LOESS X = black Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = hispan Y = student;
	LOESS X = hispan Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = treat Y = student;
	LOESS X = treat Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = married Y = student;
	LOESS X = married Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = nodegree Y = student;
	LOESS X = nodegree Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = student;
	LOESS X = predit Y = student;
	REFLINE 0;
RUN; /*On peut clairement voir une valeur extrême!*/

/*4. Normalité: pas important avec notre n*/

PROC UNIVARIATE DATA = sortie;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN;

/*5. Multicollinéarité : ok*/

/*6. Données influentes*/

PROC REG DATA = lalonde2 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF INFLUENCE;
	OUTPUT OUT = sortie P = predit STUDENT = student;
	ODS OUTPUT OutputStatistics = OutputStatistics;
	ID ID treat age educ black hispan married nodegree re74 re75;
RUN;

/*Je vérifie par rapport aux deux paramètres associés au traitement*/
DATA OutputStatistics;
	SET OutputStatistics;
	abs_DFB_treat = abs(DFB_treat);
	abs_DFB_treatXre74 = abs(DFB_treatXre74);
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treat; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treatXre74; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;
/*Il y a une observation très influente.
Les problèmes que j'ai constatés pourraient possiblement être tous dus à cette
observation influente. Je décide de la retirer. */






DATA lalonde3;
	SET lalonde2;
	WHERE ID ne 182;
RUN;

PROC REG DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF;
	OUTPUT OUT = sortie P = predit STUDENT = student;
RUN;
/*Je dois revérifier toutes les hypothèses...*/

/*1. Linéarité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = age Y = student;
	LOESS X = age Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = educ Y = student;
	LOESS X = educ Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = re74 Y = student;
	LOESS X = re74 Y = student;
	REFLINE 0;
RUN; /*Il semble y avoir une tendance résiduelle, mais 
probablement en raison d'une valeur extrême.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = re75 Y = student;
	LOESS X = re75 Y = student;
	REFLINE 0;
RUN;

/*2. Indépendance - ok selon nos connaissances*/

/*3. Homoscédasticité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = black Y = student;
	LOESS X = black Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = hispan Y = student;
	LOESS X = hispan Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = treat Y = student;
	LOESS X = treat Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = married Y = student;
	LOESS X = married Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = nodegree Y = student;
	LOESS X = nodegree Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = student;
	LOESS X = predit Y = student;
	REFLINE 0;
RUN; /*On peut clairement voir une valeur extrême!*/

/*4. Normalité: pas important avec notre n*/

PROC UNIVARIATE DATA = sortie;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN;

/*5. Multicollinéarité : ok*/

/*6. Données influentes*/

PROC REG DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF INFLUENCE;
	OUTPUT OUT = sortie P = predit STUDENT = student;
	ODS OUTPUT OutputStatistics = OutputStatistics;
	ID ID treat age educ black hispan married nodegree re74 re75;
RUN;

DATA OutputStatistics;
	SET OutputStatistics;
	abs_DFB_treat = abs(DFB_treat);
	abs_DFB_treatXre74 = abs(DFB_treatXre74);
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treat; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treatXre74; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;

/*J'utilise l'énoncé contrast pour tester l'hypothèse d'absence d'effet du traitement
et les énoncés estimate pour estimer l'effet du traitement pour différentes tranches de revenu en 74.*/
PROC GLM DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat|re74 age educ black hispan married nodegree re74 re75 / SOLUTION CLPARM SS3;
	CONTRAST "Effet traitement" treat 1, treat*re74 1;
	ESTIMATE "Effet traitement pour revenu 0" treat 1 treat*re74 0;
	ESTIMATE "Effet traitement pour revenu 2000" treat 1 treat*re74 2000;
	ESTIMATE "Effet traitement pour revenu 5000" treat 1 treat*re74 5000;
RUN; QUIT;
/*Le traitement semble très efficace pour les gens sans revenu (différence de revenu
en 78 = 2831$, IC à 95%: 1226$ à 4437$). Pour ceux ayant un revenu de 2000$, le programme
semble également avoir été efficace, bien que les données sont compatibles avec un effet
négligeable du programme (différence = 1537$, IC à 95%: 34$ à 3040$). Pour les gens ayant un
revenu de 5000$, les données ne permettent pas de conclure concernant l'efficacité du programme,
puisqu'elles sont à la fois compatible avec un effet positif, négatif et nul du programme
(différence =  -404$, IC à 95%: -2073$ à 1265$).

/*Puisqu'il semble rester une observation assez influente, mais beaucoup moins que la première.
Je la retire pour comparer mes résultats.*/


DATA lalonde4;
	SET lalonde3;
	WHERE ID ne 181;
RUN;


PROC REG DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF;
	OUTPUT OUT = sortie P = predit STUDENT = student;
RUN;

/*1. Linéarité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = age Y = student;
	LOESS X = age Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = educ Y = student;
	LOESS X = educ Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = re74 Y = student;
	LOESS X = re74 Y = student;
	REFLINE 0;
RUN; /*Il semble y avoir une tendance résiduelle, mais 
probablement en raison d'une valeur extrême.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = re75 Y = student;
	LOESS X = re75 Y = student;
	REFLINE 0;
RUN;

/*2. Indépendance - ok selon nos connaissances*/

/*3. Homoscédasticité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = black Y = student;
	LOESS X = black Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = hispan Y = student;
	LOESS X = hispan Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = treat Y = student;
	LOESS X = treat Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = married Y = student;
	LOESS X = married Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = nodegree Y = student;
	LOESS X = nodegree Y = student;
	REFLINE 0;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = student;
	LOESS X = predit Y = student;
	REFLINE 0;
RUN; /*On peut clairement voir une valeur extrême!*/

/*4. Normalité: pas important avec notre n*/

PROC UNIVARIATE DATA = sortie;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN;

/*5. Multicollinéarité : ok*/

/*6. Données influentes*/

PROC REG DATA = lalonde4 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF INFLUENCE;
	OUTPUT OUT = sortie P = predit STUDENT = student;
	ODS OUTPUT OutputStatistics = OutputStatistics;
	ID ID treat age educ black hispan married nodegree re74 re75;
RUN;

DATA OutputStatistics;
	SET OutputStatistics;
	abs_DFB_treat = abs(DFB_treat);
	abs_DFB_treatXre74 = abs(DFB_treatXre74);
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treat; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treatXre74; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;

/*Il reste trois observations se démarquant, mais beaucoup moins qu'avant*/

PROC GLM DATA = lalonde4 PLOTS = NONE;
	MODEL re78 = treat|re74 age educ black hispan married nodegree re74 re75 / SOLUTION CLPARM SS3;
	CONTRAST "Effet traitement" treat 1, treat*re74 1;
	ESTIMATE "Effet traitement pour revenu 0" treat 1 treat*re74 0;
	ESTIMATE "Effet traitement pour revenu 2000" treat 1 treat*re74 2000;
	ESTIMATE "Effet traitement pour revenu 5000" treat 1 treat*re74 5000;
RUN; QUIT;
/*Les conclusions sont qualitativement restés similaires par rapport aux
précédents. Je décide donc de ne pas retirer de nouvelles observations.
Je présenterais les résultats en ne retirant qu'une observation en mentionnant
qu'une analyse en retirant une deuxième observation possiblement influente a été
menée et que les résultats obtenus étaient similaires.*/
