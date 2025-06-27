ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des données*/
PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2014\Données\fram12.csv"
	OUT = fram12
	REPLACE
	DBMS = CSV;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = fram12 VARNUM; RUN;

PROC PRINT DATA = fram12 (OBS = 10); RUN;

/*Quelques statistiques descriptives*/
PROC MEANS DATA = fram12 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR totchol1 age1 sysbp1 diabp1 cursmoke1 cigpday1 bmi1 
		heartrte1 glucose1 sysbp2;
RUN;
/*On remarque des valeurs extrêmes*/

PROC FREQ DATA = fram12;
	TABLE sex diabetes1 bpmeds1 educ1 prevchd1 prevap1 prevmi1 prevstrk1 prevhyp1;
RUN;
/*Il y a de très petites fréquences pour certaines variables. Je ne considèrerai
pas individuellement AP, MI et STRK.*/

/*********************EXEMPLE CONTEXTE PRÉDICTION*********************/

/*On veut construire un modèle permettant de prédire la SBP à la deuxième
période en fonction de variables mesurées à la première période. L'approche
idéale consiste à guider le choix des variables par nos connaissances de la 
littérature scientifique.

Dans cet exemple, je suppose que les connaissances à ce sujet sont peu avancées. 
Je choisis donc une approche exploratoire où les données guideront le choix des
variables (procédure de sélection automatique).

Pour tout de même bien déterminer le pouvoir prédictif du modèle construit, je
diviserai le jeu de données en deux parties. Un partie d'entraînement (2/3) et une
partie de validation (1/3). La partie de validation ne doit aucunement servir dans
le choix des variables, pas même avec des statistiques descriptives*/

DATA entrainement validation;
	SET fram12;
	entrainement = ranbin(4317981, 1, 2/3); /*Je crée une variable entrainement
		qui a une probabilité 2/3 de valoir 1.*/
	IF entrainement = 1 THEN OUTPUT entrainement;
	ELSE OUTPUT validation;
	KEEP randid totchol1 age1 sysbp1 diabp1 cursmoke1 cigpday1 bmi1 
		heartrte1 glucose1 sex diabetes1 bpmeds1 educ1 prevchd1
		prevhyp1 sysbp2;
RUN;

/*Je pourrais commencer par effectuer quelques statistiques descriptives
pour déterminer s'il y a une association entre les variables sélectionnées
et l'issue que je cherche à prédire*/

PROC CORR DATA = entrainement PEARSON SPEARMAN;
	VAR sysbp2;
	WITH totchol1 age1 sysbp1 diabp1 cigpday1 bmi1
		 heartrte1 glucose1;
RUN; /*Toutes les corrélations sont statistiquement significatives.
Celles pour SBP et DBP se démarquent particulièrement. 
Il n'y a généralement pas trop de différence entre la corrélation
linéaire de Pearson et la corrélation monotone de Spearman, ce qui
peut suggérer que l'hypothèse de linéarité semble raisonable a priori
et qu'il n'y a pas trop d'observations très influentes.
En effet, la corrélation de Spearman est non-paramétrique et est
robuste aux valeurs extrêmes.

On pourrait aussi tracer avec SGPLOT des graphiques de la variable
à prédire en fonction de chacune des variables prédictrices en ajoutant
une courbe de tendance.*/

PROC SGPLOT DATA = entrainement;
	SCATTER X = totchol1 Y = sysbp2;
	LOESS X = totchol1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = age1 Y = sysbp2;
	LOESS X = age1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = sysbp1 Y = sysbp2;
	LOESS X = sysbp1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = diabp1 Y = sysbp2;
	LOESS X = diabp1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = cigpday1 Y = sysbp2;
	LOESS X = cigpday1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = bmi1 Y = sysbp2;
	LOESS X = bmi1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = heartrte1 Y = sysbp2;
	LOESS X = heartrte1 Y = sysbp2;
RUN;

PROC SGPLOT DATA = entrainement;
	SCATTER X = glucose1 Y = sysbp2;
	LOESS X = glucose1 Y = sysbp2;
RUN;

/*Les relations semblent effectivement assez linéaires,
mais certaines valeurs extrêmes d'IMC et de glucose pourraient être
influentes sur les résultats... Pour l'instant, je décide
de ne rien faire, mais je garde ces informations en tête.*/

PROC TABULATE DATA = entrainement;
	VAR sysbp2;
	CLASS sex diabetes1 bpmeds1 educ1 prevchd1 prevhyp1;
	TABLE sex diabetes1 bpmeds1 educ1 prevchd1 prevhyp1, sysbp2*(mean std);
RUN; /*Le sexe et l'éducation semblent assez peu associés avec la pression systolique*/

/*J'effectue la sélection automatique de variable sur toutes
les variables avec une approche pas-à-pas selon le BIC.*/

PROC GLMSELECT DATA = entrainement;
	CLASS sex diabetes1 bpmeds1 educ1 prevchd1 prevhyp1 /DESCENDING;
	MODEL SYSBP2 = totchol1 age1 sysbp1 diabp1 cursmoke1 cigpday1 bmi1 
		heartrte1 glucose1 sex diabetes1 bpmeds1 educ1 prevchd1
		prevhyp1 / SELECTION = STEPWISE(CHOOSE = BIC SELECT = BIC) SHOWPVALUES;
RUN; QUIT;

/*Je vérifie les hypothèses sur le modèle sélectionné.
Note: Probablement que la stratégie idéale à ce sujet serait de vérifier
les hypothèses à la fois sur le modèle complet, avant sélection, et sur
le modèle choisit. En effet, le respect des hypothèses peut dépendre du
modèle exact considéré et peut affecter le choix des variables.*/

PROC REG DATA = entrainement;
	MODEL SYSBP2 = age1 SYSBP1 BMI1 diabetes1 prevhyp1 / VIF;
	OUTPUT OUT = sortie STUDENT = student P = predit COOKD = cookd;
	ID RANDID;
RUN; QUIT;


/*1. Linéarité: à vérifier uniquement pour les variables dont on suppose
dans le modèle que l'effet est linéaire (ici: AGE1, SYSBP1 et BMI1)*/

PROC SGPLOT DATA = sortie;
	SCATTER X = AGE1 Y = student;
	LOESS X = AGE1 Y = student;
	REFLINE 0;
RUN;  /*Aucune tendance résiduelle, hypothèse semble respectée.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = SYSBP1 Y = student;
	LOESS X = SYSBP1 Y = student;
	REFLINE 0;
RUN;  /*Très légère tendance résiduelle, hypothèse semble respectée.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = BMI1 Y = student;
	LOESS X = BMI1 Y = student;
	REFLINE 0;
RUN;/*Très légère tendance résiduelle, hypothèse semble respectée.*/

/* 2. Indépendance: Selon nos connaissances du contexte de 
l'étude, il s'agirait d'observations indépendantes.*/

/* 3. Homoscédasticité : Pas vraiment important dans un contexte
de prédiction, à moins qu'on construise des ICs sur les valeurs prédites.*/

/* 4. Normalité : Pas vraiment pertinent dans notre cas, car 
1) n est assez grand, 2) on ne veut pas construire d'IC pour les valeurs 
prédites.*/
	 
/* 5. Tous les VIFs sont < 10, il ne semble donc pas y avoir de problème de
multicollinéarité. Autrement dit, pas de variables redondantes.*/

/* 6. Données inlfuentes ou aberrantes: dans notre contexte, on
s'intéresse à l'influence sur les paramètres associés à l'exposition*/

PROC SORT DATA = sortie; BY DESCENDING cookd; RUN;
PROC PRINT DATA = sortie (OBS = 20);
	VAR RANDID age1 SYSBP1 BMI1 diabetes1 prevhyp1 cookd;
RUN;

PROC SGPLOT DATA = sortie;
	NEEDLE Y = cookd X = RANDID;
RUN;

/*Il ne semble pas y avoir d'observations particulièrement influentes
sur les prédictions.*/



/*Tester le modèle sur l'ensemble de validation*/

PROC MEANS DATA = validation MEAN;
	VAR sysbp2;
RUN; 

DATA validation;
	SET validation;
	predit = 40.91105 + 0.26658*age1 + 0.58223*sysbp1 
			+ 0.13679*BMI1 + 3.92749*DIABETES1 + 7.55847*PREVHYP1;
	e2 = (sysbp2 - predit)**2;
	y_ybar2 = (sysbp2 - 137.2545732)**2;
RUN; QUIT;

PROC MEANS DATA = validation SUM;
	VAR e2 y_ybar2;
RUN;
/*R2 = 1 - (sum e2)/(sum y_ybar2)
= 1 - 260316.96/522338.48 = 0.50,
un peu plus petit que 0.53 obtenu sur l'ensemble d'entraînement.*/ 

/*Si on réestimait les paramètres sur ces nouvelles données 
(c'est seulement une expérience, ce n'est pas conseillé de le faire en pratique) */
PROC REG DATA = validation;
	MODEL SYSBP2 = age1 SYSBP1 BMI1 diabetes1 prevhyp1;
RUN; QUIT;

/*Entraînement:
Intercept 1 40.91105 3.67833 11.12 <.0001 
AGE1      1  0.26658 0.04400  6.06 <.0001 
SYSBP1    1  0.58223 0.02406 24.19 <.0001 
BMI1      1  0.13679 0.09275  1.47 0.1404 
DIABETES1 1  3.92749 2.37565  1.65 0.0984 
PREVHYP1  1  7.55847 1.05833  7.14 <.0001 


Validation:
Intercept 1 36.10452 5.25846  6.87 <.0001 
AGE1      1  0.24870 0.06544  3.80 0.0002 
SYSBP1    1  0.63957 0.03449 18.55 <.0001 
BMI1      1  0.12967 0.13569  0.96 0.3395 
DIABETES1 1  0.18405 3.40491  0.05 0.9569 
PREVHYP1  1  3.53525 1.58857  2.23 0.0263 

On remarque que les paramètres estimés sur les données
de validation sont généralement plus petits que ceux
sur les données d'entraînement. En effet, la sélection de variables
basée sur les données est connue pour introduire un biais
de surestimation de l'effet (dans la direction opposée de 0),
le biais est possiblement particulièrement grand pour diabete
et prevhyp.*/
