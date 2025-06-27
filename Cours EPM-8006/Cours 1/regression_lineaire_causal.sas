ODS HTML CLOSE;
ODS HTML;
ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des donn�es*/
PROC IMPORT DATAFILE = "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2015\Donn�es\fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

/*V�rifier que l'importation s'est bien d�roul�e*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 10); RUN;

/*Si le jeu de donn�es n'avait pas d�j� eu un identifiant,
on aurait pu en cr�er un en faisant:

DATA fram1;
	SET fram1;
	ID + 1;
RUN;
*/

/*Quelques statistiques descriptives*/
PROC MEANS DATA = fram1 MIN Q1 MEAN MEDIAN Q3 MAX STD;
	VAR age sysbp diabp bmi CIGPDAY;
RUN;
*On remarque des valeurs douteuses pour la SBP;

PROC FREQ DATA = fram1;
	TABLE sex cursmoke diabetes;
RUN;

/*En pratique, il est important de bien v�rifier imm�diatement s'il n'y aurait pas des erreurs
dans le jeu de donn�es. Par exemple, en �tudiant davantage les donn�es extr�mes d�couvertes.
On peut aussi faire certaines v�rifications logiques, par exemple que cursmoke = 0 si
cigpday = 0.*/

PROC MEANS DATA = fram1;
	CLASS cursmoke;
	VAR cigpday;
RUN;

/*********************EXEMPLE CONTEXTE CAUSAL*********************/

/*On veut estimer l'effet du tabagisme sur la pression art�rielle systolique.
Puisqu'on dispose de donn�es transversales, la t�che est plus difficile.
On essaie de choisir les variables d'ajustement autant que possible en se basant
sur nos connaissances du domaine d'application. Si on ne dispose pas de connaissances
suffisantes pour construire un DAG complet, VanderWeele et Shpitser (2011) sugg�rent
d'ajuster pour toutes les variables qui sont soient une cause de l'exposition, soit une
cause de l'issue (et qui ne sont pas des effets de l'exposition !).

J'ajuste pour l'�ge, le sexe, l'IMC. Je n'ajuste pas pour la DBP qui est probablement
influenc�e par le tabagisme. Pour le statut diab�tique, la situation est plus compliqu�e.
L'hypertension peut mener au ou aggraver les sympt�mes du diab�te. Parall�lement, le diab�te
pourrait causer de l'hypertension en raison des dommages caus�s aux art�res par le diab�te. 
Je d�cide d'ajuster pour le diab�te, mais � titre d'�tude de sensibilit�, il serait bien
d'�galement pr�senter un mod�le sans ajustement pour le diab�te. 

Je dois �galement d�cider de la fa�on dont j'entre les variables dans le mod�le. 
Pour l'exposition, j'introduis � la fois les variables cursmoke et cigpday 
(l'exposition sera repr�sent�e par deux variables). J'entre les variables
AGE, BMI et CIGPDAY de fa�on lin�aire pour simplifier. Si l'hypoth�se de lin�arit�
n'est pas respect�e, j'apporterai les correctifs n�cessaires. Les variables indicatrices (0/1) 
des variables SEX, CURSMOKE et DIABETES seront entr�es dans le mod�le. Je n'inclus pas de 
variables d'interaction. Toutefois, remarquons que pour le tabagisme, il y a une relation
sp�ciale entre les deux variables (CIGPDAY = 0 <=> cursomke = 0).
*/

/*Dans un contexte causal, il est g�n�ralement recommand� de pr�senter des statistiques
descritptives en fonction du statut d'exposition.
(Moyenne + SD ou nombre + % selon le type de variable).
Ce genre de tableau nous donne un indice de l'importance des variables
potentiellement confondantes identifi�es.

Ces statistiques descriptives pourraient aussi me montrer que certaines cat�gories de
variables cat�goriques auraient des effectifs trop petits, ce qui pourrait m'inciter
� combiner ensemble des cat�gories adjacentes.*/

PROC MEANS DATA = fram1 MEAN STD;
	CLASS cursmoke;
	VAR age sysbp bmi;
RUN;

PROC FREQ DATA = fram1;
	TABLE (sex diabetes)*cursmoke;
RUN;

/*J'ajuste le mod�le de r�gression lin�aire et je fais sortir
diff�rents fichiers pour v�rifier les hypoth�ses du mod�le.
PROC REG et PROC GLM peuvent �tre utilis�s pour des estimations
par les moindres carr�s. PROC REG permet plus facilement la v�rification
des hypoth�ses.*/

PROC REG DATA = fram1;
	MODEL SYSBP = cursmoke cigpday sex age bmi diabetes / VIF CLB;
	OUTPUT OUT = sortie STUDENT = student P = predit;
RUN; QUIT;

/*1. Lin�arit�: � v�rifier uniquement pour les variables dont on suppose
dans le mod�le que l'effet est lin�aire (ici: CIGPDAY, AGE et BMI)*/

PROC SGPLOT DATA = sortie;
	SCATTER X = cigpday Y = student;
	LOESS X = cigpday Y = student;
	REFLINE 0;
RUN;  /*Aucune tendance r�siduelle, hypoth�se semble respect�e.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = age Y = student;
	LOESS X = age Y = student;
	REFLINE 0;
RUN;  /*Aucune tendance r�siduelle, hypoth�se semble respect�e.
(Par contre, on voit une forme d'entonoir qui pourrait �tre
un signe d'h�t�rosc�dasticit�.)*/

PROC SGPLOT DATA = sortie;
	SCATTER X = bmi Y = student;
	LOESS X = bmi Y = student;
	REFLINE 0;
RUN; /*On constate une l�g�re tendance aux deux extr�mes qui
pourrait �tre caus�e par des valeurs extr�mes de BMI.*/

/* 2. Ind�pendance: Selon nos connaissances du contexte de 
l'�tude, il s'agirait d'observations ind�pendantes.*/

/* 3. Homosc�dasticit� : Nous avons d�j� constat� un probl�me pour �ge.
Pour les variables cigpday et bmi, il ne semblait pas y avoir de probl�me.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = student;
	REFLINE 0;
RUN; /*Il semble y avoir une certaine forme d'entonnoir*/

PROC SGPLOT DATA = sortie;
	SCATTER X = sex Y = student;
	REFLINE 0;
RUN; /*Les deux barres sont similaires - hypoth�se respect�e*/

PROC SGPLOT DATA = sortie;
	SCATTER X = cursmoke Y = student;
	REFLINE 0;
RUN;  /*Les deux barres sont similaires - hypoth�se respect�e*/

PROC SGPLOT DATA = sortie;
	SCATTER X = diabetes Y = student;
	REFLINE 0;
RUN; /*Les deux barres semblent diff�rentes, mais il faut se souvenir
qu'il y a beaucoup moins de sujets diab�tiques que non diab�tiques.
Si on calcule l'�cart-type des r�sidus par cat�gorie :*/
PROC MEANS DATA = sortie STD VAR;
	CLASS diabetes;
	VAR student;
RUN; /*On constate une diff�rence de 32% dans les �carts-types. 
C'est une diff�rence notable.*/

/* 4. Normalit� : Pas vraiment pertinent dans notre cas, car n est
assez grand.*/

PROC UNIVARIATE DATA = sortie NORMAL;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN; /*Il y a une l�g�re d�viation par rapport � la droite attendue*/
	 
/* 5. Tous les VIFs sont < 10, il ne semble donc pas y avoir de probl�me de
multicollin�arit�.*/

/* 6. Donn�es inlfuentes ou aberrantes: dans notre contexte, on
s'int�resse � l'influence sur les param�tres associ�s � l'exposition*/

PROC REG DATA = fram1;
	MODEL SYSBP = cursmoke cigpday sex age bmi diabetes / INFLUENCE;
	ODS OUTPUT OutputStatistics = OutputStatistics;
	ID RANDID SYSBP cursmoke cigpday sex age bmi diabetes;
RUN; QUIT;

DATA OutputStatistics;
	SET OutputStatistics;
	abs_DFB_cursmoke = abs(DFB_cursmoke);
	abs_DFB_cigpday = abs(DFB_cigpday);
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_cursmoke; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20);
	VAR RANDID SYSBP cursmoke cigpday sex age bmi diabetes abs_DFB_cursmoke;
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_cigpday; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20);
	VAR RANDID SYSBP cursmoke cigpday sex age bmi diabetes abs_DFB_cigpday;
RUN;
/*Il ne semble pas y avoir d'observations particuli�rement influentes
sur les param�tres associ�s au tabagisme.

Si j'avais voulu supprimer l'observation 3533652, j'aurais pu ex�cuter le code:

DATA fram1_1;
	SET fram1;
	IF RANDID = 3533652 THEN DELETE;
RUN;*/


/*En somme, le probl�me principal semble �tre l'h�t�rosc�dasticit�.
On pourrait consid�rer une transformation de la variable SYSBP. Une telle
transformation va cependant rendre les r�sultats plus difficiles � interpr�ter.
L'autre possibilit� est d'utiliser un estimateur robuste :*/


/*Estimateur robuste*/
ODS GRAPHICS OFF;
PROC REG DATA = fram1;
	MODEL SYSBP = cursmoke cigpday sex age bmi diabetes / VIF CLB WHITE;
	OUTPUT OUT = sortie STUDENT = student P = predit;
	EffetTabagisme: TEST cursmoke = 0, cigpday = 0;
RUN; QUIT;

/*Malheureusement, PROC REG n'offre pas de possibilit�s pour 
estimer des combinaisons de param�tres... On pourrait utiliser
PROC MIXED qui permet un estimateur robuste 
par le maximum de vraisemblance*/

PROC MIXED DATA = fram1 EMPIRICAL;
	CLASS RANDID;
	MODEL SYSBP = cursmoke cigpday sex age bmi diabetes / SOLUTION CL;
	CONTRAST "EffetTabagisme" cursmoke 1, cigpday 1;
	ESTIMATE "10 cig/day vs 0" cursmoke 1 cigpday 10 /CL;
	ESTIMATE "20 cig/day vs 0" cursmoke 1 cigpday 20 /CL;
	REPEATED / SUBJECT = RANDID TYPE = VC;
RUN;

/*Transformation:*/
ODS GRAPHICS OFF;

DATA fram1b;
	SET fram1;
	log_SYSBP = log(SYSBP);
RUN;

PROC REG DATA = fram1b;
	MODEL log_SYSBP = cursmoke cigpday sex age bmi diabetes / VIF CLB;
	OUTPUT OUT = sortie STUDENT = student P = predit;
RUN; QUIT;

/*Apr�s une modification au mod�le, il faudrait rev�rifier les hypoth�ses pour ce nouveau mod�le.
Les hypoth�ses semblent beaucoup mieux respect�es (non pr�sent�).
Pour IMC, on semble voir une l�g�re tendance quadratique, mais qui pourrait
possiblement �tre attribuable � des valeurs extr�mes d'IMC. */

PROC GLM DATA = fram1b;
	MODEL log_SYSBP = cursmoke cigpday sex age bmi diabetes / CLPARM SOLUTION SS3;
	CONTRAST "Effet tabagisme" cursmoke 1, cigpday 1;
	ESTIMATE "10 cig/day vs 0" cursmoke 1 cigpday 10;
	ESTIMATE "20 cig/day vs 0" cursmoke 1 cigpday 20;
RUN;



/*Conclusion: On ne peut pas rejetter l'hypoth�se qu'il n'y a pas
de lien entre le tabagisme et la pression art�rielle systolique. 
Ceci ne veut pas dire qu'on conclut qu'il n'y a pas d'effet du tabagisme
sur la pression systolique. Les ICs obtenus d�montrent une compatibilit� 
des donn�es � la fois avec un effet positif, une absence d'effet et un
effet n�gatif. Les donn�es sont donc peu informatives. Par ailleurs,
il est fort probable qu'il reste un biais de confusion r�siduel d� � des
variables non utilis�es, telle que le niveau d'�ducation ou le statut socio-�conomique.*/



