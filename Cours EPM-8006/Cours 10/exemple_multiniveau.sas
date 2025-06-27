PROC IMPORT OUT = mmmec
	DATAFILE = "C:\Users\etudiant\Documents\EPM-8006\donnees\mmec.csv"
	REPLACE
	DBMS = CSV;
RUN;

PROC CONTENTS DATA = mmmec VARNUM; RUN;

PROC PRINT DATA = mmmec; RUN;

PROC MEANS DATA = mmmec;
	CLASS nation;
	VAR RR UVB;
RUN;

PROC MIXED DATA = mmmec COVTEST;
	CLASS nation region county;
	MODEL RR =  / OUTPM = sortie VCIRY SOLUTION;
	RANDOM intercept / SUBJECT = nation;
	RANDOM intercept / SUBJECT = region(nation);
RUN;

PROC MIXED DATA = mmmec COVTEST;
	CLASS nation region county;
	MODEL RR = UVB / OUTPM = sortie VCIRY SOLUTION;
	RANDOM intercept / SUBJECT = nation;
	RANDOM intercept / SUBJECT = region(nation);
RUN;



PROC MIXED DATA = mmmec COVTEST EMPIRICAL;
	CLASS nation region county;
	MODEL RR = UVB / OUTPM = sortie VCIRY SOLUTION CL;
	RANDOM intercept UVB / SUBJECT = nation TYPE = UN;
	RANDOM intercept / SUBJECT = region(nation);
RUN;

/* Calcul des valeurs prédites transformées */
data sortie2;
  set sortie;
	predt = scaleddep - scaledresid;
run;
/* Diagramme de dispersion des résidus transformés vs. valeurs prédites transformées */
PROC SGPLOT DATA = sortie2;
	SCATTER X = predt Y = scaledresid;
run;


