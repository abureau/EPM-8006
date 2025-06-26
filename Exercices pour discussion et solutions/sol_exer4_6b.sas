/*Importation des donn�es*/
PROC IMPORT DATAFILE = "C:\Users\deta001\Dropbox\Travail\Cours\EPM8006\Automne 2015\Donn�es\fram12.csv"
	OUT = fram12
	REPLACE
	DBMS = CSV;
RUN;

/*V�rification que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = fram12 VARNUM; RUN;

PROC PRINT DATA = fram12 (OBS = 20); RUN;

/*Construction des nouvelles variables
et m�nage pour ne conserver que les variables pertinentes*/
DATA fram12b;
	SET fram12;
	/*Il ne devrait pas y avoir de donn�es manquantes,
	mais il faut normallement faire attention quand 
	on utilise des �nonc�s IF et ELSE aux donn�es manquantes*/
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
/*Il y a de forts d�s�quilibres entre les deux groupes
par rapport � la majorit� des variables. Seul l'�ducation 
semble assez bien �quilibr�s.
On constate aussi des valeurs assez extr�mes pour l'IMC,
� garder en t�te pour les analyses.*/

/*Ajustement du mod�le de r�gression logistique*/

/*D�terminer l'association brute*/
PROC GENMOD DATA = fram12b DESCENDING;
	MODEL hypertension2 = cursmoke2 / dist=binomial link= log lrci;
	estimate "tabagisme T2" cursmoke2 1;
RUN;

/*RR = 0.76 IC � 95% 0.70 � 0.83.
Le tabagisme est associ� � une r�duction du risque
d'hypertension*/

PROC genmod DATA = fram12b DESCENDING;
	CLASS educ1 randid / PARAM = REF;
	MODEL hypertension2 = cursmoke2 hypertension1 age1 sex bmi1 educ1 prevchd1 / dist=poisson link= log;
	REPEATED subject=randid;
	estimate "tabagisme T2" cursmoke2 1;
	OUTPUT OUT = sortie DFBETA = dfbeta RESCHI = resid;
RUN;

/*V�rification des hypoth�ses du mod�le*/

/* On va se concentrer sur les r�sidus de Pearson. Les r�sidus de d�viance ne sont pas appropri�s ici
   car ils seront calcul�s en supposant une distribution de Poisson alors que la distribution est en 
   fait binomiale */

/*1. Lin�arit�*/
PROC SGPLOT DATA = sortie;
	SCATTER X = age1 Y = resid;
	LOESS X = age1 Y = resid;
	REFLINE 0;
RUN; *Aucune tendance r�siduelle;

PROC SGPLOT DATA = sortie;
	SCATTER X = bmi1 Y = resid;
	LOESS X = bmi1 Y = resid;
	REFLINE 0;
RUN; *Tr�s l�g�re tendance dans les extr�mes,
probablement due aux donn�es extr�mes d'IMC;

/*2. Ind�pendance :
Pas de probl�me � notre connaissance*/

/*3. Multicollin�arit�*/
/*On a d�j� v�rifi� en 4.6a qu'aucune variable n'a de VIF > 10. Pas besoin de refaire car ne d�pend pas
  de la forme du mod�le */

/*4. Donn�es extr�mes ou aberrantes*/
DATA sortie2;
	SET sortie;
	absDFbeta = abs(DFbeta);
RUN;

PROC SORT DATA = sortie2; BY DESCENDING absDFbeta; RUN;
PROC PRINT DATA = sortie2 (OBS = 30); RUN;

*Ou graphiquement;
PROC SGPLOT DATA = sortie2;
	NEEDLE X = randid Y = absDFbeta;
RUN;

/*Rien ne se d�marque, pas de probl�me*/

/*5. s�paration, pas de probl�me, sinon on aurait eu
un message dans la sortie de SAS*/

/*6. Sur-dispersion:
On est dans le cas bernouilli (parce qu'il
y a des variables explicatives continues) et non binomial, on ne
peut pas avoir ce probl�me*/

/*Tout semble ok*/

PROC genmod DATA = fram12b DESCENDING;
	CLASS educ1 randid / PARAM = REF;
	MODEL hypertension2 = cursmoke2 hypertension1 age1 sex bmi1 educ1 prevchd1 / dist=poisson link= log;
	REPEATED subject=randid;
	estimate "tabagisme T2" cursmoke2 1;
RUN;

/*RR = 1.01, IC = 0.94 � 1.09 ,
Les donn�es ne permettent pas de conclure concernant l'effet du tabagisme
sur le risque d'hypertension.*/



