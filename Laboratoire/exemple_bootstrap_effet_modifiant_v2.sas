/*Importation des données*/
PROC IMPORT DATAFILE = "C:\Users\AlexandreBureau\Documents\EPM-8006\donnees\fram1.csv"
	OUT = fram1
	REPLACE
	DBMS = CSV;
RUN;

DATA fram1b;
	SET fram1;
	cursmokeXsex = cursmoke*sex;
RUN;

PROC PRINT DATA = fram1b (OBS = 10); RUN;

ODS TRACE ON;

ODS LISTING;
PROC GENMOD DATA = fram1b;
	CLASS RANDID;
	MODEL diabetes = cursmoke sex cursmokeXsex age bmi SYSBP DIABP / DIST = poisson LINK = log COVB;
	REPEATED SUBJECT = RANDID;
	ESTIMATE "Femme fum vs femme non fum" cursmoke 1;
	ESTIMATE "homme non fum vs femme non fum" sex 1;
	ESTIMATE "homme fum vs femme non fum" sex 1 cursmoke 1 cursmokeXsex 1;
	ODS OUTPUT Estimates = Estimates;
RUN; 


ODS TRACE OFF;

PROC PRINT DATA = estimates; RUN;

/*Pour calculer le RERI à partir des sorties, je
dois passer à un format large;*/

DATA reri1; SET estimates; WHERE label = "homme fum vs femme non fum"; Terme1 = MeanEstimate; KEEP Terme1; RUN;
DATA reri2; SET estimates; WHERE label = "homme non fum vs femme non fum"; Terme2 = MeanEstimate; KEEP Terme2; RUN;
DATA reri3; SET estimates; WHERE label = "Femme fum vs femme non fum"; Terme3 = MeanEstimate; KEEP Terme3; RUN;

DATA RERI;
	MERGE reri1-reri3;
	RERI = terme1 - terme2 - terme3 + 1;
RUN;
PROC PRINT DATA = reri; RUN;


/*Exemple 1 avec PROC SURVEYSELECT*/
PROC SURVEYSELECT DATA = fram1b
	METHOD = URS /*Unrestricted random sampling*/
	SAMPRATE = 1 /*n pigé = n total*/
	SEED = 571895 /*Germe pour contrôler le hasard*/
	REP = 1000 /*Nombre d'échantillons bootstrap*/
	OUTHITS /*Option nécessaire*/
	OUT = fram1b_boot; /*Sortie*/
RUN;

PROC GENMOD DATA = fram1b_boot;
	BY replicate;
	CLASS RANDID;
	MODEL diabetes = cursmoke sex cursmokeXsex age bmi SYSBP DIABP / DIST = poisson LINK = log COVB;
	REPEATED SUBJECT = RANDID;
	ESTIMATE "Femme fum vs femme non fum" cursmoke 1;
	ESTIMATE "homme non fum vs femme non fum" sex 1;
	ESTIMATE "homme fum vs femme non fum" sex 1 cursmoke 1 cursmokeXsex 1;
	ODS OUTPUT Estimates = Estimates;
	ODS SELECT Estimates;
RUN; 

DATA reri1; SET estimates; WHERE label = "homme fum vs femme non fum"; Terme1 = MeanEstimate; KEEP Terme1; RUN;
DATA reri2; SET estimates; WHERE label = "homme non fum vs femme non fum"; Terme2 = MeanEstimate; KEEP Terme2; RUN;
DATA reri3; SET estimates; WHERE label = "Femme fum vs femme non fum"; Terme3 = MeanEstimate; KEEP Terme3; RUN;

DATA RERI;
	MERGE reri1-reri3;
	RERI = terme1 - terme2 - terme3 + 1;
RUN;
PROC PRINT DATA = reri; RUN;

PROC UNIVARIATE DATA = reri;
	VAR reri;
	OUTPUT OUT = sortie PCTLPTS = 2.5 97.5 PCTLPRE = p_;
RUN;

PROC PRINT DATA = sortie; RUN;
/*-2.59307 -0.099715  */

PROC SGPLOT DATA = RERI;
	HISTOGRAM reri;
	DENSITY reri / TYPE = KERNEL;
	REFLINE -2.59307 -0.099715  / AXIS = X; 
RUN;

DATA reri;
	SET reri;
	sqrt_reri = sign(reri)*sqrt(abs(reri));
	log_reri = log(reri + 5);
RUN;

PROC UNIVARIATE DATA = RERI;
	VAR sqrt_reri;
	QQPLOT sqrt_reri / NORMAL(MU = est SIGMA = EST);
RUN;




/*Exemple 2 avec macro*/

%MACRO ANALYZE(Data = , out=,);
PROC GENMOD DATA = &data;
	%BYSTMT;
	CLASS RANDID;
	MODEL diabetes = cursmoke sex cursmokeXsex age bmi SYSBP DIABP / DIST = poisson LINK = log COVB;
	REPEATED SUBJECT = RANDID;
	ESTIMATE "Femme fum vs femme non fum" cursmoke 1;
	ESTIMATE "homme non fum vs femme non fum" sex 1;
	ESTIMATE "homme fum vs femme non fum" sex 1 cursmoke 1 cursmokeXsex 1;
	ODS OUTPUT Estimates = Estimates;
	ODS SELECT Estimates;
RUN; QUIT;

DATA reri1; SET estimates; WHERE label = "homme fum vs femme non fum"; Terme1 = MeanEstimate; KEEP Terme1 _sample_; RUN;
DATA reri2; SET estimates; WHERE label = "homme non fum vs femme non fum"; Terme2 = MeanEstimate; KEEP Terme2 _sample_; RUN;
DATA reri3; SET estimates; WHERE label = "Femme fum vs femme non fum"; Terme3 = MeanEstimate; KEEP Terme3 _sample_; RUN;

DATA &out;
	MERGE reri1-reri3;
	RERI = terme1 - terme2 - terme3 + 1;
	KEEP RERI _sample_;
RUN;
%MEND;

/* Exemple d'appel de la macro */
%ANALYZE(Data=fram1b,out=test);
run;

/*Inclure le fichier jackboot.sas contenant les macros*/
%INCLUDE "C:\Users\AlexandreBureau\Documents\EPM-8006\cours bootstrap\jackboot.sas";

%BOOT(DATA = fram1b, samples = 1000, stat = RERI);
/*L'appel à BOOTCI est très long à exécuter*/
%BOOTCI(METHOD = BCA, stat = RERI);
