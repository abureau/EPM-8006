/*Importation des données*/
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/fram12.csv"
	OUT = fram12
	REPLACE
	DBMS = CSV;
RUN;

/*Vérification que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = fram12 VARNUM; RUN;

PROC PRINT DATA = fram12 (OBS = 20); RUN;

/*Construction des nouvelles variables
et ménage pour ne conserver que les variables pertinentes*/
DATA fram12b;
	SET fram12;
	/*Il ne devrait pas y avoir de données manquantes,
	mais il faut normallement faire attention quand 
	on utilise des énoncés IF et ELSE aux données manquantes*/
	IF sysbp1 ne . AND diabp1 ne . AND BPMEDS1 ne . THEN
		IF sysbp1 > 140 OR diabp1 > 90 OR BPMEDS1 = 1 THEN hypertension1 = 1;
		ELSE IF sysbp1 <= 140 AND diabp1 <= 90 AND BPMEDS1 = 0 THEN hypertension1 = 0;
	IF sysbp2 ne . AND diabp2 ne . AND BPMEDS2 ne . THEN
		IF sysbp2 > 140 OR diabp2 > 90 OR BPMEDS2 = 1 THEN hypertension2 = 1;
		ELSE IF sysbp2 <= 140 AND diabp2 <= 90 AND BPMEDS2 = 0 THEN hypertension2 = 0;
	KEEP randid hypertension2 cursmoke2 age1 sex hypertension1 BMI1 educ1 prevchd1;
RUN;

/*Quelques statistiques descriptives*/
PROC MEANS DATA = fram12b MEAN STD MIN Q1 MEDIAN Q3 MAX;
	CLASS cursmoke2;
	VAR age1 sex hypertension1 BMI1 educ1 prevchd1 hypertension2;
RUN;
/*Il y a de forts déséquilibres entre les deux groupes
par rapport à la majorité des variables. Seul l'éducation 
semble assez bien équilibrés.
On constate aussi des valeurs assez extrêmes pour l'IMC,
à garder en tête pour les analyses.*/

/*Ajustement du modèle de régression logistique*/

/*Déterminer l'association brute*/
PROC LOGISTIC DATA = fram12b DESCENDING;
	MODEL hypertension2 = cursmoke2 / CL;
RUN;

/*RC = 0.624 IC à 95% 0.537 à 0.725.
Le tabagisme est associé à une réduction du risque
d'hypertension*/

PROC LOGISTIC DATA = fram12b DESCENDING;
	CLASS educ1 / PARAM = REF;
	MODEL hypertension2 = cursmoke2 hypertension1 age1 sex bmi1 educ1 prevchd1 / CL AGGREGATE SCALE = NONE;
	OUTPUT OUT = sortie DFBETA = df0 df1 STDRESCHI = resid;
	ID randid;
RUN;

/*Vérification des hypothèses du modèle*/

/*1. Linéarité*/
PROC SGPLOT DATA = sortie;
	SCATTER X = age1 Y = resid;
	LOESS X = age1 Y = resid;
	REFLINE 0;
RUN; *Aucune tendance résiduelle;

PROC SGPLOT DATA = sortie;
	SCATTER X = bmi1 Y = resid;
	LOESS X = bmi1 Y = resid;
	REFLINE 0;
RUN; *Très légère tendance dans les extrêmes,
probablement due aux données extrêmes d'IMC;

/*2. Indépendance :
Pas de problème à notre connaissance*/

/*3. Multicollinéarité*/
/*On doit le tester avec PROC REG,
on doit donc créer des indicatrices pour l'éducation si 
on considère cette variable comme catégorique.*/

DATA fram12c;
	SET fram12b;
	IF educ1 ne . THEN
		IF educ1 = 1 THEN DO;
			educ_1 = 1; educ_2 = 0; educ_3 = 0;
			END;
		ELSE IF educ1 = 2 THEN DO;
			educ_1 = 0; educ_2 = 1; educ_3 = 0;
			END;
		ELSE IF educ1 = 3 THEN DO;
			educ_1 = 0; educ_2 = 0; educ_3 = 1;
			END;
		ELSE IF educ1 = 4 THEN DO;
			educ_1 = 0; educ_2 = 0; educ_3 = 0;
			END;
RUN;
*Juste vérifier que les indicatrices ont bien été créées;
PROC FREQ DATA = fram12c;
	TABLE educ1*(educ_1 educ_2 educ_3);
RUN; *Tout est ok;

*Régression bidon;
PROC REG DATA = fram12c PLOTS = NONE;
	MODEL randid = cursmoke2 hypertension1 age1 sex bmi1 educ_1 educ_2 educ_3 prevchd1 / VIF;
RUN; QUIT; /*Aucun VIF > 10*/

/*4. Données extrêmes ou aberrantes*/
DATA sortie2;
	SET sortie;
	absDF1 = abs(DF1);
RUN;

PROC SORT DATA = sortie2; BY DESCENDING absDF1; RUN;
PROC PRINT DATA = sortie2 (OBS = 30); RUN;

*Ou graphiquement;
PROC SGPLOT DATA = sortie2;
	NEEDLE X = randid Y = absDF1;
RUN;

/*Rien ne se démarque, pas de problème*/

/*5. séparation, pas de problème, sinon on aurait eu
un message dans la sortie de SAS*/

/*6. Sur-dispersion:
On est dans le cas bernouilli (parce qu'il
y a des variables explicatives continues) et non binomial, on ne
peut pas avoir ce problème*/

/*Tout semble ok*/

PROC LOGISTIC DATA = fram12b DESCENDING;
	CLASS educ1 / PARAM = REF;
	MODEL hypertension2 = cursmoke2 hypertension1 age1 sex bmi1 educ1 prevchd1 / CL AGGREGATE SCALE = NONE;
RUN;
/*RC = 1.056, IC = 0.872 à 1.278 ,
Les données ne permettent pas de conclure concernant l'effet du tabagisme
sur le risque d'hypertension.*/



