
/***** Calcul de taille d'�chantillon *********/

PROC POWER;
	MULTREG ALPHA = 0.05
			POWER = 0.8
			MODEL = FIXED
			NTESTPRED = 1 /*Nombre de variables d'int�r�t (exposition)*/
			NTOTAl = .
			PARTIALCORR = 0.1 /*Corr�lation partielle entre les variables d'int�r�t
							 et la r�ponse apr�s ajustement pour les variables confondantes.*/
			NFULLPRED = 10; /*Nombre total de variables dans le mod�le*/
	PLOT X = power MIN = 0.5 MAX = 0.95;
RUN;



/****** Calcul de la corr�lation partielle *******/

PROC IMPORT DATAFILE = "C:\...\fram12.csv"
	OUT = fram12
	REPLACE
	DBMS = CSV;
RUN;

PROC CORR DATA = fram12;
	VAR SYSBP2; *Y, r�ponse;
	WITH CURSMOKE2; *X, exposition;
	PARTIAL AGE1 CURSMOKE1 SEX SYSBP1; *U, variables potentiellement confondantes; 
RUN;


