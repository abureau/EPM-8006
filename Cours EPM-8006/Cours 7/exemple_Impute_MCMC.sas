*Je consid�re l'estimation de l'effet
causal conditionnel avec imputation MCMC;

*J'importe le fichier osteo5 nettoy�.;
PROC IMPORT DATAFILE = "C:\Users\etudiant\Documents\EPM-8006\donnees\osteo5.csv"
	OUT = osteo
	DBMS = CSV
	REPLACE;
RUN;

proc freq data=osteo;
table alq130*alq101;
run;

/* Remplissage et correction des valeurs de alq130 en supposant que alq101 est correct*/
data osteo;
set osteo;
if alq101 = 2 then alq130 = 0;
run;

PROC MEANS DATA = osteo NMISS N;
	VAR OSQ010A;
RUN;

/*************************Approche conditionnelle**********************************/

*On va consid�rer consommation r�guli�re ou vari�e vs jamais consommation r�guli�re
pour avoir une exposition binaire.;
DATA osteo_bin;
	SET osteo;
	IF cons_reg = 1 OR cons_var = 1 THEN cons = 1;
	ELSE IF cons_reg = 0 AND cons_var = 0 THEN cons = 0;

	*Je cr�e des indicatrices pour la variable cat�gorique;
	IF RIDRETH1 NE . THEN DO;
		IF RIDRETH1 = 1 THEN mex_am = 1; ELSE mex_am = 0;
		IF RIDRETH1 = 2 THEN aut_hisp = 1; ELSE aut_hisp = 0;
		IF RIDRETH1 = 3 THEN blanc_nh = 1; ELSE blanc_nh = 0;
		IF RIDRETH1 = 4 THEN noir_nh = 1; ELSE noir_nh = 0;
	END;

	KEEP OSQ130 OSQ170 OSQ200 RIAGENDR RIDRETH1 RIDAGEYR 
		 BMXBMI MCQ160C MCQ160L WHD020 WHD110 ALQ101 ALQ130
		 cons SEQN OSQ010A
		 mex_am--noir_nh; *A--B veut dire toutes les variables dans le jeu de donn�es entre A et B;
RUN;

*Je fais d'abord 0 imputations, juste pour connaitre mon taux de donn�es manquantes;
PROC MI DATA = osteo_bin NIMPUTE = 0;
RUN; *Seulement 48.7% de mes observations sont compl�tes,
taux de donn�es manquantes d'environ 51%, donc 51 imputations.;

*J'impute toutes les variables comme si elles �taient continues;

PROC MI DATA = osteo_bin NIMPUTE = 51 OUT = osteo_mi SEED = 1479471; /*SEED ou germe pour assurer d'avoir toujours le m�me hasard*/
	VAR OSQ130 OSQ170 OSQ200 RIAGENDR  mex_am--noir_nh RIDAGEYR 
		 BMXBMI MCQ160C MCQ160L WHD020 WHD110 ALQ101 ALQ130
		 cons OSQ010A ;
/* On pourrait ajouter des options MIN =, MAX =, ROUND = 
   pour dire � SAS les mins et maxs pour chacune de nos variables, dans leur
   ordre d'apparition dans l'�nonc� VAR (. si pas de min ou de max). ROUND fonctionne de
   fa�on similaire et indique comment les variables doivent �tre arrondies (10, 1, 0.1, 0.01).
   TOUTEFOIS, beaucoup de litt�rature sur les imputations sugg�rent qu'il est mieux de ne pas
   arrondir et de ne pas limiter les valeurs imput�es, bien qu'elles peuvent sortir des
   limites th�oriques. Par ailleurs, les options MIN et MAX font souvent en sorte de
   faire �chouer l'imputation.*/

	MCMC NBITER = 200 /*Nombre de "burn-in iterations", la premi�re s�rie inutilis�e*/
		 NITER = 100 /*Nombre d'it�rations entre chaque imputation conserv�e (1/100)*/
		 PLOTS = (ALL ACF(NLAG = 50)); /*Pour faire afficher les graphiques diagnostics*/
RUN; /*Tr�s court � ex�cuter en comparaison avec l'imputation par �quations chain�es!*/
/*Les graphiques semblent corrects*/

PROC MEANS DATA = osteo_mi MIN MEAN MAX;
	VAR _numeric_;
RUN; /*Certaines valeurs sortes des limites possibles, c'est
ennuyeux...*/

PROC FREQ DATA = osteo_mi;
	TABLE cons;
RUN;
/*... particuli�rement pour la variable d'exposition!*/

DATA osteo_mi2;
	SET osteo_mi;
	/*Puisqu'il y avait tr�s peu de donn�es manquantes
	pour la r�ponse, j'arrondi arbitrairement � 0.5*/
	IF OSQ010A < 1.5 THEN OSQ010A = 1;
	ELSE OSQ010A = 2;
RUN;

/*
Pour combiner le r�sultats, nous utiliserons MIANALYZE,
il faudra sortir des r�sultats de nos analyses pour les
fournir � MIANALYZE;
Dans l'aide de SAS pour MIANALYZE, je trouve un exemple
qui utilise PROC LOGISTIC, je fais un copi�-coll� de la syntaxe.

proc logistic data=outfish2;
   class Species;
   model Species= Length Width / covb;
   by _Imputation_;
   ods output ParameterEstimates=lgsparms;
run;

proc mianalyze parms=lgsparms;
   modeleffects Intercept Length Width;
run;
*/

PROC LOGISTIC DATA = osteo_mi2; *Pas d'option noprint possible;
	*WHERE _imputation_ = 1;
	BY _imputation_;
	MODEL OSQ010A = cons OSQ130 OSQ170 OSQ200 RIAGENDR  mex_am--noir_nh RIDAGEYR 
		 BMXBMI MCQ160C MCQ160L WHD020 WHD110 ALQ101 ALQ130
		 cons SEQN / LINK = logit ; 
	ODS OUTPUT ParameterEstimates=lgsparms;
RUN;
*Je n'ai regard� que quelques imputations, mais pour chacune, 
la consommation est associ�e � une r�duction du risque de fracture;

PROC MIANALYZE PARMS = lgsparms;
	MODELEFFECTS Intercept cons OSQ130 OSQ170 OSQ200 RIAGENDR mex_am aut_hisp blanc_nh noir_nh RIDAGEYR 
		 BMXBMI MCQ160C MCQ160L WHD020 WHD110 ALQ101 ALQ130;
RUN;
*RC = exp(-0.674242) = 0.51
IC = (exp(-1.16713), exp(-0.18135)) = (0.31, 0.83)
 
pas tr�s diff�rent de ce qu'on avait trouv� avec l'approche marginale; 
