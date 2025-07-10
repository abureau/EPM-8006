ODS HTML CLOSE;
ODS HTML;
ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/*Importation des données*/
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;


/*Modèle de base*/
PROC REG DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI / CLB;
RUN; QUIT;

PROC GLM DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI / CLPARM;
RUN; QUIT;

PROC MIXED DATA = fram1; /*MV*/
	MODEL SYSBP = Sex Age BMI / SOLUTION CL;
RUN;


/*Tests d'hypothèses simultanés et contrastes*/
DATA fram1b;
	SET fram1;
	sexXcursmoke = sex*cursmoke;
RUN;

PROC REG DATA = fram1b; /*MCO*/
	MODEL SYSBP = sex cursmoke sexXcursmoke / CLB;
	EffetFum: TEST cursmoke = 0, sexXcursmoke = 0;
RUN; QUIT;

PROC GLM DATA = fram1; /*MCO*/
	MODEL SYSBP = sex cursmoke sex*cursmoke / CLPARM;
	CONTRAST "Effet fum" cursmoke 1, sex*cursmoke 1;
	ESTIMATE "Fumeur vs n-fumeur H" cursmoke 1 sex*cursmoke 1;
RUN; QUIT;

PROC MIXED DATA = fram1; /*MV*/
	MODEL SYSBP = sex cursmoke sex*cursmoke / SOLUTION CL;
	CONTRAST "Effet fum" cursmoke 1, sex*cursmoke 1;
	ESTIMATE "Fumeur vs n-fumeur H" cursmoke 1 sex*cursmoke 1;
RUN;


/*Linéarité*/
PROC REG DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI;
	OUTPUT OUT = sortie STUDENT = resid;
RUN; QUIT;

PROC GLM DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI;
	OUTPUT OUT = sortie STUDENT = resid;
RUN; QUIT;

PROC MIXED DATA = fram1; /*MV*/
	MODEL SYSBP = Sex Age BMI / OUTPM = sortie RESIDUAL;
RUN;

PROC SGPLOT DATA = sortie;
	SCATTER X = BMI Y = Studentresid;
	LOESS X = BMI Y = Studentresid / smooth=0.5;
	REFLINE 0;
RUN;

/* Même graphique avec proc loess 
   L'option plots = fitplot requis pour produire courbe de lissage 
   L'option select permet de choisir le degré de lissage. 
   Pour l'exprimer en terme de degrés de liberté, utiliser df1(k) 
   où k est le nombre de degrés de liberté.
*/
ODS GRAPHICS ON; 
PROC LOESS DATA = sortie plots(maxpoints=none) = fitplot;
MODEL Studentresid = BMI / CLM SELECT=DF1(5);
RUN;

/*Estimateur robuste*/
PROC REG DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI / WHITE;
	OUTPUT OUT = sortie STUDENT = resid P = predit;
RUN; QUIT;

PROC MIXED DATA = fram1 EMPIRICAL; /*MV*/
	CLASS RANDID;
	MODEL SYSBP = Sex Age BMI / SOLUTION CL OUTPM = sortie RESIDUAL;
	REPEATED / SUBJECT = RANDID TYPE = VC;
RUN;

/*Normalité*/
PROC UNIVARIATE DATA = sortie;
	VAR Studentresid;
	QQPLOT Studentresid / NORMAL (MU = 0 SIGMA = 1);
RUN;

/*VIF*/
PROC REG DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI / VIF;
RUN; QUIT;

/*Données influentes*/
PROC REG DATA = fram1; /*MCO*/
	MODEL SYSBP = Sex Age BMI / INFLUENCE;
	OUTPUT OUT = sortie COOKD = Cook;
	ODS OUTPUT OutputStatistics = OutputStatistics;
	ID RANDID SYSBP Sex Age BMI;
RUN; QUIT;

DATA OutputStatistics;
	SET OutputStatistics;
	abs_DFB_BMI = abs(DFB_BMI);
RUN;

PROC SORT DATA = OutputStatistics; BY DESCENDING abs_DFB_BMI; RUN;
PROC PRINT DATA = OutputStatistics (OBS = 20);
	VAR RANDID Sex Age BMI abs_DFB_BMI;
RUN;

PROC SGPLOT DATA = OutputStatistics;
	NEEDLE X = RANDID Y = abs_DFB_BMI;
RUN;

















