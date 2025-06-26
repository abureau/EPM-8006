/*Importation des donn�es*/
PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2015\Donn�es\lalonde.csv"
	OUT = lalonde
	REPLACE
	DBMS = CSV;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = lalonde VARNUM; RUN;

/*Je calcule des statistiques descriptives selon
l'exposition. Je constate des valeurs extr�mes pour le revenu.*/
PROC MEANS DATA = lalonde MEAN STD SUM MIN Q1 MEDIAN Q3 MAX;
	CLASS treat;
	VAR age educ black hispan married nodegree re74 re75 re78;
RUN;

/*J'ajoute un identifiant et je cr�e une variable
d'interaction pour PROC REG*/
DATA lalonde2;
	SET lalonde;
	treatXre74 = treat*re74;
	ID + 1;
RUN;

/*J'ajuste le mod�le de r�gression lin�aire et je v�rifie les hypoth�ses*/
PROC REG DATA = lalonde2 PLOTS = NONE;
	MODEL re78 = treat treatXre74 age educ black hispan married nodegree re74 re75 / VIF;
	OUTPUT OUT = sortie P = predit STUDENT = student;
RUN; QUIT;


/*1. Lin�arit�*/
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
RUN; /*Il semble y avoir une tendance r�siduelle, mais 
probablement en raison d'une valeur extr�me.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = re75 Y = student;
	LOESS X = re75 Y = student;
	REFLINE 0;
RUN;

/*2. Ind�pendance - ok selon nos connaissances*/

/*3. Homosc�dasticit�*/
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
RUN; /*On peut clairement voir une valeur extr�me!*/

/*4. Normalit�: pas important avec notre n*/

PROC UNIVARIATE DATA = sortie;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN;

/*5. Multicollin�arit� : ok*/

/*6. Donn�es influentes*/

PROC REG DATA = lalonde2 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF INFLUENCE;
	OUTPUT OUT = sortie P = predit STUDENT = student;
	ODS OUTPUT OutputStatistics = OutputStatistics;
	ID ID treat age educ black hispan married nodegree re74 re75;
RUN;

/*Je v�rifie par rapport aux deux param�tres associ�s au traitement*/
DATA OutputStatistics;
	SET OutputStatistics;
	abs_DFB_treat = abs(DFB_treat);
	abs_DFB_treatXre74 = abs(DFB_treatXre74);
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treat; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_treatXre74; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20); RUN;
/*Il y a une observation tr�s influente.
Les probl�mes que j'ai constat�s pourraient possiblement �tre tous dus � cette
observation influente. Je d�cide de la retirer. */






DATA lalonde3;
	SET lalonde2;
	WHERE ID ne 182;
RUN;

PROC REG DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF;
	OUTPUT OUT = sortie P = predit STUDENT = student;
RUN;
/*Je dois rev�rifier toutes les hypoth�ses...*/

/*1. Lin�arit�*/
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
RUN; /*Il semble y avoir une tendance r�siduelle, mais 
probablement en raison d'une valeur extr�me.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = re75 Y = student;
	LOESS X = re75 Y = student;
	REFLINE 0;
RUN;

/*2. Ind�pendance - ok selon nos connaissances*/

/*3. Homosc�dasticit�*/
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
RUN; /*On peut clairement voir une valeur extr�me!*/

/*4. Normalit�: pas important avec notre n*/

PROC UNIVARIATE DATA = sortie;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN;

/*5. Multicollin�arit� : ok*/

/*6. Donn�es influentes*/

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

/*J'utilise l'�nonc� contrast pour tester l'hypoth�se d'absence d'effet du traitement
et les �nonc�s estimate pour estimer l'effet du traitement pour diff�rentes tranches de revenu en 74.*/
PROC GLM DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat|re74 age educ black hispan married nodegree re74 re75 / SOLUTION CLPARM SS3;
	CONTRAST "Effet traitement" treat 1, treat*re74 1;
	ESTIMATE "Effet traitement pour revenu 0" treat 1 treat*re74 0;
	ESTIMATE "Effet traitement pour revenu 2000" treat 1 treat*re74 2000;
	ESTIMATE "Effet traitement pour revenu 5000" treat 1 treat*re74 5000;
RUN; QUIT;
/*Le traitement semble tr�s efficace pour les gens sans revenu (diff�rence de revenu
en 78 = 2831$, IC � 95%: 1226$ � 4437$). Pour ceux ayant un revenu de 2000$, le programme
semble �galement avoir �t� efficace, bien que les donn�es sont compatibles avec un effet
n�gligeable du programme (diff�rence = 1537$, IC � 95%: 34$ � 3040$). Pour les gens ayant un
revenu de 5000$, les donn�es ne permettent pas de conclure concernant l'efficacit� du programme,
puisqu'elles sont � la fois compatible avec un effet positif, n�gatif et nul du programme
(diff�rence =  -404$, IC � 95%: -2073$ � 1265$).

/*Puisqu'il semble rester une observation assez influente, mais beaucoup moins que la premi�re.
Je la retire pour comparer mes r�sultats.*/


DATA lalonde4;
	SET lalonde3;
	WHERE ID ne 181;
RUN;


PROC REG DATA = lalonde3 PLOTS = NONE;
	MODEL re78 = treat age treatXre74 educ black hispan married nodegree re74 re75 / VIF;
	OUTPUT OUT = sortie P = predit STUDENT = student;
RUN;

/*1. Lin�arit�*/
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
RUN; /*Il semble y avoir une tendance r�siduelle, mais 
probablement en raison d'une valeur extr�me.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = re75 Y = student;
	LOESS X = re75 Y = student;
	REFLINE 0;
RUN;

/*2. Ind�pendance - ok selon nos connaissances*/

/*3. Homosc�dasticit�*/
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
RUN; /*On peut clairement voir une valeur extr�me!*/

/*4. Normalit�: pas important avec notre n*/

PROC UNIVARIATE DATA = sortie;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN;

/*5. Multicollin�arit� : ok*/

/*6. Donn�es influentes*/

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

/*Il reste trois observations se d�marquant, mais beaucoup moins qu'avant*/

PROC GLM DATA = lalonde4 PLOTS = NONE;
	MODEL re78 = treat|re74 age educ black hispan married nodegree re74 re75 / SOLUTION CLPARM SS3;
	CONTRAST "Effet traitement" treat 1, treat*re74 1;
	ESTIMATE "Effet traitement pour revenu 0" treat 1 treat*re74 0;
	ESTIMATE "Effet traitement pour revenu 2000" treat 1 treat*re74 2000;
	ESTIMATE "Effet traitement pour revenu 5000" treat 1 treat*re74 5000;
RUN; QUIT;
/*Les conclusions sont qualitativement rest�s similaires par rapport aux
pr�c�dents. Je d�cide donc de ne pas retirer de nouvelles observations.
Je pr�senterais les r�sultats en ne retirant qu'une observation en mentionnant
qu'une analyse en retirant une deuxi�me observation possiblement influente a �t�
men�e et que les r�sultats obtenus �taient similaires.*/
