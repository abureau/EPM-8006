/*Solution exercice 3.5*/

/*Note: Il serait possible de répondre à toutes les
questions à l'intérieur d'une seule procédure GLM, en
utilisant plusieurs énoncés CONTRAST et ESTIMATE, mais
je sépare chaque question pour illustrer plus clairement
les démarches*/

*Importation des données;
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/fram1.csv"
	OUT = fram1
	DBMS = csv
	REPLACE;
RUN;

*Vérifier que l'importation s'est bien déroulée;
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 20); RUN;


/**********
*    A    *
**********/

*Ajustement du modèle de régression linéaire;

*Pour insérer les termes d'interaction et quadratiques dans
PROC REG, il faudra d'abord créer ces variables.;

DATA fram1_1;
	SET fram1;
	BMI2 = BMI*BMI;
	cursmokeXage = cursmoke*age;
RUN;

ODS LISTING; *Pour obtenir une sortie dans output. Cette sortie
se copie bien dans le programme SAS;
PROC REG DATA = fram1_1 PLOTS = NONE;
	MODEL DIABP = cursmoke sex age bmi bmi2 cursmokeXage;
RUN; QUIT;


/**********
*    B    *
**********/
*Le test F du modèle précédent donne la réponse 
Model 6 104448 17408 144.26 <.0001,
mais on peut aussi construire ce test "à la main";

PROC REG DATA = fram1_1 PLOTS = NONE;
	MODEL DIABP = cursmoke sex age bmi bmi2 cursmokeXage;
	FTest: TEST cursmoke = 0, sex = 0,
				age = 0, bmi = 0, bmi2 = 0,
				cursmokeXage = 0; 
RUN; QUIT;

*On conclut qu'il existe une association entre les variables
explicatives et la variable réponse.;


/**********
*    C    *
**********/

PROC REG DATA = fram1_1 PLOTS = NONE;
	MODEL DIABP = cursmoke sex age bmi bmi2 cursmokeXage;
	EffetCursmoke: TEST cursmoke = 0, cursmokeXage = 0; 
RUN; QUIT;

/*
 Test EffetCursmoke Results for Dependent Variable DIABP

                                Mean
Source             DF         Square    F Value    Pr > F

Numerator           2      386.15677       3.20    0.0409
Denominator      4376      120.66949

On conclut qu'il existe une association entre le statut de fumeur
et la DBP.*/

/**********
*    D    *
**********/

PROC REG DATA = fram1_1 PLOTS = NONE;
	MODEL DIABP = cursmoke sex age bmi bmi2 cursmokeXage;
	EffetBMI: TEST bmi = 0, bmi2 = 0; 
RUN; QUIT;

/*
   Test EffetBMI Results for Dependent Variable DIABP

                                Mean
Source             DF         Square    F Value    Pr > F

Numerator           2          36071     298.92    <.0001
Denominator      4376      120.66949

On conclut qu'il existe une association entre l'IMC et la DBP*/

/**********
*    E    *
**********/

*Pour calculer les différences de moyennes, il faut utiliser
PROC GLM;

PROC GLM DATA = fram1_1;
	MODEL DIABP = cursmoke sex age bmi bmi2 cursmokeXage / SOLUTION SS3 CLPARM;
	ESTIMATE "IMC 30 vs 25" bmi 5 bmi2 275;
	/*30**2 - 25**2 = 275*/
RUN; QUIT;



/**********
*    F    *
**********/

/*La comparaison va dépendre de l'âge.
En observant nos statistiques descriptives,
on constate que la majorité des données sont comprises
entre 40 et 60 ans.

On va comparer le statut de fumeur à 40, 50 et 60 ans*/


PROC GLM DATA = fram1_1;
	MODEL DIABP = cursmoke sex age bmi bmi2 cursmokeXage / SOLUTION SS3 CLPARM;
	ESTIMATE "Fumeur 40 vs non-fumeur 40" cursmoke 1 cursmokeXage 40;
	ESTIMATE "Fumeur 50 vs non-fumeur 50" cursmoke 1 cursmokeXage 50;
	ESTIMATE "Fumeur 60 vs non-fumeur 60" cursmoke 1 cursmokeXage 60;
RUN; QUIT;

/* Pour les sujets de 40 ans, le fait de fumer est associé à une réduction
de la DBP de 1.3 mmHg (IC à 95%: -2.3 à -0.3 mmHg). Pour les sujets de 50 ans
les données suggèrent que le fait de fumer est associé à une réduction de la
DBP, mais les données sont également compatibles avec une absence d'association
(différence de -0.6 mmHg, IC à 95%: -1.3 à 0.05 mmHg). Pour les sujets de 60 ans, les données
sont peu informatives; des effets positifs, négatifs et nuls sont tous compatibles
avec les données (différence de 0.0 mmHg, IC à 95%: -1.0 à 1.1 mmHg).

Puisqu'il s'agit d'une étude observationnelle et que plusieurs variables potentiellement
confondantes n'ont pas été contrôlées dans le modèle, les associations observées ne peuvent
pas être interprétées de façon causale. */
