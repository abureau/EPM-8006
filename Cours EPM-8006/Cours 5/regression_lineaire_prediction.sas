ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des donn�es*/
PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2014\Donn�es\fram12.csv"
	OUT = fram12
	REPLACE
	DBMS = CSV;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = fram12 VARNUM; RUN;

PROC PRINT DATA = fram12 (OBS = 10); RUN;

/*Quelques statistiques descriptives*/
PROC MEANS DATA = fram12 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR totchol1 age1 sysbp1 diabp1 cursmoke1 cigpday1 bmi1 
		heartrte1 glucose1 sysbp2;
RUN;
/*On remarque des valeurs extr�mes*/

PROC FREQ DATA = fram12;
	TABLE sex diabetes1 bpmeds1 educ1 prevchd1 prevap1 prevmi1 prevstrk1 prevhyp1;
RUN;
/*Il y a de tr�s petites fr�quences pour certaines variables. Je ne consid�rerai
pas individuellement AP, MI et STRK.*/

/*********************EXEMPLE CONTEXTE PR�DICTION*********************/

/*On veut construire un mod�le permettant de pr�dire la SBP � la deuxi�me
p�riode en fonction de variables mesur�es � la premi�re p�riode. L'approche
id�ale consiste � guider le choix des variables par nos connaissances de la 
litt�rature scientifique.

Dans cet exemple, je suppose que les connaissances � ce sujet sont peu avanc�es. 
Je choisis donc une approche exploratoire o� les donn�es guideront le choix des
variables (proc�dure de s�lection automatique).

Pour tout de m�me bien d�terminer le pouvoir pr�dictif du mod�le construit, je
diviserai le jeu de donn�es en deux parties. Un partie d'entra�nement (2/3) et une
partie de validation (1/3). La partie de validation ne doit aucunement servir dans
le choix des variables, pas m�me avec des statistiques descriptives*/

DATA entrainement validation;
	SET fram12;
	entrainement = ranbin(4317981, 1, 2/3); /*Je cr�e une variable entrainement
		qui a une probabilit� 2/3 de valoir 1.*/
	IF entrainement = 1 THEN OUTPUT entrainement;
	ELSE OUTPUT validation;
	KEEP randid totchol1 age1 sysbp1 diabp1 cursmoke1 cigpday1 bmi1 
		heartrte1 glucose1 sex diabetes1 bpmeds1 educ1 prevchd1
		prevhyp1 sysbp2;
RUN;

/*Je pourrais commencer par effectuer quelques statistiques descriptives
pour d�terminer s'il y a une association entre les variables s�lectionn�es
et l'issue que je cherche � pr�dire*/

PROC CORR DATA = entrainement PEARSON SPEARMAN;
	VAR sysbp2;
	WITH totchol1 age1 sysbp1 diabp1 cigpday1 bmi1
		 heartrte1 glucose1;
RUN; /*Toutes les corr�lations sont statistiquement significatives.
Celles pour SBP et DBP se d�marquent particuli�rement. 
Il n'y a g�n�ralement pas trop de diff�rence entre la corr�lation
lin�aire de Pearson et la corr�lation monotone de Spearman, ce qui
peut sugg�rer que l'hypoth�se de lin�arit� semble raisonable a priori
et qu'il n'y a pas trop d'observations tr�s influentes.
En effet, la corr�lation de Spearman est non-param�trique et est
robuste aux valeurs extr�mes.

On pourrait aussi tracer avec SGPLOT des graphiques de la variable
� pr�dire en fonction de chacune des variables pr�dictrices en ajoutant
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

/*Les relations semblent effectivement assez lin�aires,
mais certaines valeurs extr�mes d'IMC et de glucose pourraient �tre
influentes sur les r�sultats... Pour l'instant, je d�cide
de ne rien faire, mais je garde ces informations en t�te.*/

PROC TABULATE DATA = entrainement;
	VAR sysbp2;
	CLASS sex diabetes1 bpmeds1 educ1 prevchd1 prevhyp1;
	TABLE sex diabetes1 bpmeds1 educ1 prevchd1 prevhyp1, sysbp2*(mean std);
RUN; /*Le sexe et l'�ducation semblent assez peu associ�s avec la pression systolique*/

/*J'effectue la s�lection automatique de variable sur toutes
les variables avec une approche pas-�-pas selon le BIC.*/

PROC GLMSELECT DATA = entrainement;
	CLASS sex diabetes1 bpmeds1 educ1 prevchd1 prevhyp1 /DESCENDING;
	MODEL SYSBP2 = totchol1 age1 sysbp1 diabp1 cursmoke1 cigpday1 bmi1 
		heartrte1 glucose1 sex diabetes1 bpmeds1 educ1 prevchd1
		prevhyp1 / SELECTION = STEPWISE(CHOOSE = BIC SELECT = BIC) SHOWPVALUES;
RUN; QUIT;

/*Je v�rifie les hypoth�ses sur le mod�le s�lectionn�.
Note: Probablement que la strat�gie id�ale � ce sujet serait de v�rifier
les hypoth�ses � la fois sur le mod�le complet, avant s�lection, et sur
le mod�le choisit. En effet, le respect des hypoth�ses peut d�pendre du
mod�le exact consid�r� et peut affecter le choix des variables.*/

PROC REG DATA = entrainement;
	MODEL SYSBP2 = age1 SYSBP1 BMI1 diabetes1 prevhyp1 / VIF;
	OUTPUT OUT = sortie STUDENT = student P = predit COOKD = cookd;
	ID RANDID;
RUN; QUIT;


/*1. Lin�arit�: � v�rifier uniquement pour les variables dont on suppose
dans le mod�le que l'effet est lin�aire (ici: AGE1, SYSBP1 et BMI1)*/

PROC SGPLOT DATA = sortie;
	SCATTER X = AGE1 Y = student;
	LOESS X = AGE1 Y = student;
	REFLINE 0;
RUN;  /*Aucune tendance r�siduelle, hypoth�se semble respect�e.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = SYSBP1 Y = student;
	LOESS X = SYSBP1 Y = student;
	REFLINE 0;
RUN;  /*Tr�s l�g�re tendance r�siduelle, hypoth�se semble respect�e.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = BMI1 Y = student;
	LOESS X = BMI1 Y = student;
	REFLINE 0;
RUN;/*Tr�s l�g�re tendance r�siduelle, hypoth�se semble respect�e.*/

/* 2. Ind�pendance: Selon nos connaissances du contexte de 
l'�tude, il s'agirait d'observations ind�pendantes.*/

/* 3. Homosc�dasticit� : Pas vraiment important dans un contexte
de pr�diction, � moins qu'on construise des ICs sur les valeurs pr�dites.*/

/* 4. Normalit� : Pas vraiment pertinent dans notre cas, car 
1) n est assez grand, 2) on ne veut pas construire d'IC pour les valeurs 
pr�dites.*/
	 
/* 5. Tous les VIFs sont < 10, il ne semble donc pas y avoir de probl�me de
multicollin�arit�. Autrement dit, pas de variables redondantes.*/

/* 6. Donn�es inlfuentes ou aberrantes: dans notre contexte, on
s'int�resse � l'influence sur les param�tres associ�s � l'exposition*/

PROC SORT DATA = sortie; BY DESCENDING cookd; RUN;
PROC PRINT DATA = sortie (OBS = 20);
	VAR RANDID age1 SYSBP1 BMI1 diabetes1 prevhyp1 cookd;
RUN;

PROC SGPLOT DATA = sortie;
	NEEDLE Y = cookd X = RANDID;
RUN;

/*Il ne semble pas y avoir d'observations particuli�rement influentes
sur les pr�dictions.*/



/*Tester le mod�le sur l'ensemble de validation*/

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
un peu plus petit que 0.53 obtenu sur l'ensemble d'entra�nement.*/ 

/*Si on r�estimait les param�tres sur ces nouvelles donn�es 
(c'est seulement une exp�rience, ce n'est pas conseill� de le faire en pratique) */
PROC REG DATA = validation;
	MODEL SYSBP2 = age1 SYSBP1 BMI1 diabetes1 prevhyp1;
RUN; QUIT;

/*Entra�nement:
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

On remarque que les param�tres estim�s sur les donn�es
de validation sont g�n�ralement plus petits que ceux
sur les donn�es d'entra�nement. En effet, la s�lection de variables
bas�e sur les donn�es est connue pour introduire un biais
de surestimation de l'effet (dans la direction oppos�e de 0),
le biais est possiblement particuli�rement grand pour diabete
et prevhyp.*/
