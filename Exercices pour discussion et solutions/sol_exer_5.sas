/*Solution exercice 5.2*/

*J'importe le fichier osteo5 nettoyé.;
PROC IMPORT DATAFILE = "/workspaces/workspace/Données EPM-8006/osteo5.csv"
	OUT = osteo
	DBMS = CSV
	REPLACE;
RUN;

PROC CONTENTS DATA = osteo VARNUM; RUN;

DATA osteo2;
	SET osteo;
	IF missing(OSQ010A) THEN missingY = 1; ELSE missingY = 0; *Pour savoir les obs ave Y manquant;
	*Je recode les variables binaires selon la codification
	usuelle 0 = non, 1 = oui;
	IF ALQ101 = 2 THEN ALQ101 = 0;
	IF OSQ010A = 2 THEN OSQ010A = 0;
	IF OSQ130 = 2 THEN OSQ130 = 0;
	IF OSQ170 = 2 THEN OSQ170 = 0;
	IF OSQ200 = 2 THEN OSQ200 = 0;
	IF RIAGENDR = 2 THEN RIAGENDR = 0;
	KEEP ALQ101 OSQ010A BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR
		 RIDAGEYR RIDRETH1 missingY; 
RUN;

PROC PRINT DATA = osteo2 (OBS = 20); RUN;
PROC FREQ DATA = osteo2;
	TABLE ALQ101 OSQ010A OSQ130 OSQ170 OSQ200 RIAGENDR
		 RIDRETH1;
RUN;

*Je fais d'abord 0 imputations, juste pour connaitre mon taux de données manquantes;
PROC MI DATA = osteo2 NIMPUTE = 0;
RUN; *81% des données sont complètes, 20 imputations suffiront;

*J'utilise l'imputation MICE étant donné que mes variables sont de différents types;
PROC MI DATA = osteo2 NIMPUTE = 20 OUT = osteo_mi SEED = 87419; /*SEED ou germe pour assurer d'avoir toujours le même hasard*/
	VAR ALQ101 OSQ010A BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR
		 RIDAGEYR RIDRETH1;
	CLASS ALQ101 OSQ010A OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1;
	FCS LOGISTIC(ALQ101 = OSQ010A BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR RIDAGEYR RIDRETH1);
	FCS LOGISTIC(OSQ010A = ALQ101 BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR RIDAGEYR RIDRETH1);
	FCS REGPMM(BMXBMI = ALQ101 OSQ010A OSQ130 OSQ170 OSQ200 RIAGENDR RIDAGEYR RIDRETH1);
	FCS LOGISTIC(OSQ130 = ALQ101 OSQ010A BMXBMI OSQ170 OSQ200 RIAGENDR RIDAGEYR RIDRETH1);
	FCS LOGISTIC(OSQ170 = ALQ101 OSQ010A BMXBMI OSQ130 OSQ200 RIAGENDR RIDAGEYR RIDRETH1);
	FCS LOGISTIC(OSQ200 = ALQ101 OSQ010A BMXBMI OSQ130 OSQ170 RIAGENDR RIDAGEYR RIDRETH1);
	FCS LOGISTIC(RIAGENDR = ALQ101 OSQ010A BMXBMI OSQ130 OSQ170 OSQ200 RIDAGEYR RIDRETH1);
	FCS REGPMM(RIDAGEYR = ALQ101 OSQ010A BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1);
	FCS LOGISTIC(RIDRETH1 = ALQ101 OSQ010A BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR RIDAGEYR); /*Par défaut, lien cumlogit pour une variable multicatégorielle*/
RUN;

DATA osteo_mi2;
	SET osteo_mi;
	WHERE missingY = 0; *Je retire les obs avec Y manquant;
	*Je crée des indicatrices pour RIDRETH1;
	IF RIDRETH1 = 1 THEN mex_am = 1; ELSE mex_am = 0;
	IF RIDRETH1 = 2 THEN aut_hisp = 1; ELSE aut_hisp = 0;
	IF RIDRETH1 = 3 THEN blanc_nh = 1; ELSE blanc_nh = 0;
	IF RIDRETH1 = 4 THEN noir_nh = 1; ELSE noir_nh = 0;
RUN;

*Calcul de l'association - il y a un exemple dans PROC MIANALYZE pour la régression logistique;
PROC LOGISTIC DATA = osteo_mi2 DESCENDING; 
	BY _imputation_; *Un modèle pour chaque imputation;
	MODEL OSQ010A = ALQ101 BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR
		 RIDAGEYR mex_am aut_hisp blanc_nh noir_nh /COVB;
	ODS OUTPUT ParameterEstimates=lgsparms;
RUN; 

PROC PRINT DATA = lgsparms; RUN;

PROC MIANALYZE PARMS = lgsparms;
	CLASS RIDRETH1;
	MODELEFFECTS ALQ101 BMXBMI OSQ130 OSQ170 OSQ200 RIAGENDR
		 RIDAGEYR mex_am aut_hisp blanc_nh noir_nh;
RUN;
*RC = exp(-0.411760) = 0.66
IC = (exp(-0.99651), exp(0.172992)) = (0.37, 1.19);
*La consommation d'alcool semble associée à une réduction du
risque de fracture de la hance. La nature transversale des données et
le risque de confusion résiduelle empèche d'interpréter causalement
cette association. Par ailleurs, une consommation de 12 boissons alcoolisées
au cours d'une année n'est pas une consommation extrême. Il est donc possible
que des consommations modérées avec un effet neutre ou même positif soient
combinées avec des consommations élevées ayant un effet négatif dans la 
variable d'exposition utilisée.
