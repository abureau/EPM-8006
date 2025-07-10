ODS HTML CLOSE;
ODS HTML;
ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des données*/
PROC IMPORT DATAFILE = "/workspaces/myfolder/Données EPM-8006/fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

/*Vérifier que l'importation s'est bien déroulée*/
PROC CONTENTS DATA = fram1 VARNUM; RUN;

PROC PRINT DATA = fram1 (OBS = 10); RUN;

/*Si le jeu de données n'avait pas déjà eu un identifiant,
on aurait pu en créer un en faisant:

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

/*En pratique, il est important de bien vérifier immédiatement s'il n'y aurait pas des erreurs
dans le jeu de données. Par exemple, en étudiant davantage les données extrêmes découvertes.
On peut aussi faire certaines vérifications logiques, par exemple que cursmoke = 0 si
cigpday = 0.*/

PROC MEANS DATA = fram1;
	CLASS cursmoke;
	VAR cigpday;
RUN;

/*********************EXEMPLE CONTEXTE CAUSAL*********************/

/*On veut estimer l'effet du tabagisme sur la pression artérielle systolique.
Puisqu'on dispose de données transversales, la tâche est plus difficile.
On essaie de choisir les variables d'ajustement autant que possible en se basant
sur nos connaissances du domaine d'application. Si on ne dispose pas de connaissances
suffisantes pour construire un DAG complet, VanderWeele et Shpitser (2011) suggèrent
d'ajuster pour toutes les variables qui sont soient une cause de l'exposition, soit une
cause de l'issue (et qui ne sont pas des effets de l'exposition !).

J'ajuste pour l'âge, le sexe, l'IMC. Je n'ajuste pas pour la DBP qui est probablement
influencée par le tabagisme. Pour le statut diabétique, la situation est plus compliquée.
L'hypertension peut mener au ou aggraver les symptômes du diabète. Parallèlement, le diabète
pourrait causer de l'hypertension en raison des dommages causés aux artères par le diabète. 
Je décide d'ajuster pour le diabète, mais à titre d'étude de sensibilité, il serait bien
d'également présenter un modèle sans ajustement pour le diabète. 

Je dois également décider de la façon dont j'entre les variables dans le modèle. 
Pour l'exposition, j'introduis à la fois les variables cursmoke et cigpday 
(l'exposition sera représentée par deux variables). J'entre les variables
AGE, BMI et CIGPDAY de façon linéaire pour simplifier. Si l'hypothèse de linéarité
n'est pas respectée, j'apporterai les correctifs nécessaires. Les variables indicatrices (0/1) 
des variables SEX, CURSMOKE et DIABETES seront entrées dans le modèle. Je n'inclus pas de 
variables d'interaction. Toutefois, remarquons que pour le tabagisme, il y a une relation
spéciale entre les deux variables (CIGPDAY = 0 <=> cursomke = 0).
*/

/*Dans un contexte causal, il est généralement recommandé de présenter des statistiques
descritptives en fonction du statut d'exposition.
(Moyenne + SD ou nombre + % selon le type de variable).
Ce genre de tableau nous donne un indice de l'importance des variables
potentiellement confondantes identifiées.

Ces statistiques descriptives pourraient aussi me montrer que certaines catégories de
variables catégoriques auraient des effectifs trop petits, ce qui pourrait m'inciter
à combiner ensemble des catégories adjacentes.*/

PROC MEANS DATA = fram1 MEAN STD;
	CLASS cursmoke;
	VAR age sysbp bmi;
RUN;

PROC FREQ DATA = fram1;
	TABLE (sex diabetes)*cursmoke;
RUN;

/*J'ajuste le modèle de régression linéaire et je fais sortir
différents fichiers pour vérifier les hypothèses du modèle.
PROC REG et PROC GLM peuvent être utilisés pour des estimations
par les moindres carrés. PROC REG permet plus facilement la vérification
des hypothèses.*/

PROC REG DATA = fram1;
	MODEL SYSBP = cursmoke cigpday sex age bmi diabetes / VIF CLB;
	OUTPUT OUT = sortie STUDENT = student P = predit;
RUN; QUIT;

/*1. Linéarité: à vérifier uniquement pour les variables dont on suppose
dans le modèle que l'effet est linéaire (ici: CIGPDAY, AGE et BMI)*/

PROC SGPLOT DATA = sortie;
	SCATTER X = cigpday Y = student;
	LOESS X = cigpday Y = student;
	REFLINE 0;
RUN;  /*Aucune tendance résiduelle, hypothèse semble respectée.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = age Y = student;
	LOESS X = age Y = student;
	REFLINE 0;
RUN;  /*Aucune tendance résiduelle, hypothèse semble respectée.
(Par contre, on voit une forme d'entonoir qui pourrait être
un signe d'hétéroscédasticité.)*/

PROC SGPLOT DATA = sortie;
	SCATTER X = bmi Y = student;
	LOESS X = bmi Y = student;
	REFLINE 0;
RUN; /*On constate une légère tendance aux deux extrêmes qui
pourrait être causée par des valeurs extrêmes de BMI.*/

/* 2. Indépendance: Selon nos connaissances du contexte de 
l'étude, il s'agirait d'observations indépendantes.*/

/* 3. Homoscédasticité : Nous avons déjà constaté un problème pour âge.
Pour les variables cigpday et bmi, il ne semblait pas y avoir de problème.*/

PROC SGPLOT DATA = sortie;
	SCATTER X = predit Y = student;
	REFLINE 0;
RUN; /*Il semble y avoir une certaine forme d'entonnoir*/

PROC SGPLOT DATA = sortie;
	SCATTER X = sex Y = student;
	REFLINE 0;
RUN; /*Les deux barres sont similaires - hypothèse respectée*/

PROC SGPLOT DATA = sortie;
	SCATTER X = cursmoke Y = student;
	REFLINE 0;
RUN;  /*Les deux barres sont similaires - hypothèse respectée*/

PROC SGPLOT DATA = sortie;
	SCATTER X = diabetes Y = student;
	REFLINE 0;
RUN; /*Les deux barres semblent différentes, mais il faut se souvenir
qu'il y a beaucoup moins de sujets diabétiques que non diabétiques.
Si on calcule l'écart-type des résidus par catégorie :*/
PROC MEANS DATA = sortie STD VAR;
	CLASS diabetes;
	VAR student;
RUN; /*On constate une différence de 32% dans les écarts-types. 
C'est une différence notable.*/

/* 4. Normalité : Pas vraiment pertinent dans notre cas, car n est
assez grand.*/

PROC UNIVARIATE DATA = sortie NORMAL;
	VAR student;
	QQPLOT student / NORMAL(MU = 0 SIGMA = 1);
RUN; /*Il y a une légère déviation par rapport à la droite attendue*/
	 
/* 5. Tous les VIFs sont < 10, il ne semble donc pas y avoir de problème de
multicollinéarité.*/

/* 6. Données inlfuentes ou aberrantes: dans notre contexte, on
s'intéresse à l'influence sur les paramètres associés à l'exposition*/

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
/*Il ne semble pas y avoir d'observations particulièrement influentes
sur les paramètres associés au tabagisme.

Si j'avais voulu supprimer l'observation 3533652, j'aurais pu exécuter le code:

DATA fram1_1;
	SET fram1;
	IF RANDID = 3533652 THEN DELETE;
RUN;*/


/*En somme, le problème principal semble être l'hétéroscédasticité.
On pourrait considérer une transformation de la variable SYSBP. Une telle
transformation va cependant rendre les résultats plus difficiles à interpréter.
L'autre possibilité est d'utiliser un estimateur robuste :*/


/*Estimateur robuste*/
ODS GRAPHICS OFF;
PROC REG DATA = fram1;
	MODEL SYSBP = cursmoke cigpday sex age bmi diabetes / VIF CLB WHITE;
	OUTPUT OUT = sortie STUDENT = student P = predit;
	EffetTabagisme: TEST cursmoke = 0, cigpday = 0;
RUN; QUIT;

/*Malheureusement, PROC REG n'offre pas de possibilités pour 
estimer des combinaisons de paramètres... On pourrait utiliser
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

/*Après une modification au modèle, il faudrait revérifier les hypothèses pour ce nouveau modèle.
Les hypothèses semblent beaucoup mieux respectées (non présenté).
Pour IMC, on semble voir une légère tendance quadratique, mais qui pourrait
possiblement être attribuable à des valeurs extrêmes d'IMC. */

PROC GLM DATA = fram1b;
	MODEL log_SYSBP = cursmoke cigpday sex age bmi diabetes / CLPARM SOLUTION SS3;
	CONTRAST "Effet tabagisme" cursmoke 1, cigpday 1;
	ESTIMATE "10 cig/day vs 0" cursmoke 1 cigpday 10;
	ESTIMATE "20 cig/day vs 0" cursmoke 1 cigpday 20;
RUN;



/*Conclusion: On ne peut pas rejetter l'hypothèse qu'il n'y a pas
de lien entre le tabagisme et la pression artérielle systolique. 
Ceci ne veut pas dire qu'on conclut qu'il n'y a pas d'effet du tabagisme
sur la pression systolique. Les ICs obtenus démontrent une compatibilité 
des données à la fois avec un effet positif, une absence d'effet et un
effet négatif. Les données sont donc peu informatives. Par ailleurs,
il est fort probable qu'il reste un biais de confusion résiduel dû à des
variables non utilisées, telle que le niveau d'éducation ou le statut socio-économique.*/



