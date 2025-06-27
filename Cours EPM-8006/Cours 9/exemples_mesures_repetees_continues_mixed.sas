/*Lecture des donn�es*/
DATA seizure;
	INFILE "seizure.data";
	INPUT ID Counts Visit TX Age Weeks;
RUN;

/*Afficher les donn�es*/
PROC PRINT DATA = seizure (OBS = 10); RUN;

/*Le jeu de donn�es est dans ce qu'on appelle un format long, c'est-�-dire
que chaque ligne repr�sente une visite pour un sujet. C'est ce qu'il
faut pour effectuer les analyses.*/

/* Cr�er un jeu de donn�es avec les valeurs au d�part
plac�e dans des variables s�par�es*/
DATA baseline;
	SET seizure;
	WHERE Visit = 0;
	Counts0 = counts;
	Age0 = Age;
	KEEP ID Counts0 Age0;
RUN;

PROC SORT DATA = baseline; BY id; RUN;
PROC SORT DATA = seizure; BY id; RUN;


DATA seizure2;
	MERGE seizure baseline;
	BY ID;
	IF Visit = 0 THEN DELETE;
RUN;


/*Mod�le mixte - 1*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX /s;
	REPEATED / SUBJECT = ID TYPE = AR(1);
RUN;

/*Mod�le mixte - 2*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX /s;
	RANDOM intercept / SUBJECT = ID;
RUN;

/*Mod�le mixte - 3 (avec Counts0 en covariable)*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
	CLASS ID TX(REF = first);
	MODEL counts = visit|TX Counts0/s alpha=0.05 ; 
	RANDOM intercept visit / SUBJECT = ID TYPE = UN;
RUN; 





/*Mod�le mixte*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
	CLASS ID TX(REF = first);
	ID ID Visit TX; /*Pour dire � SAS comment identifier les obs*/
	MODEL counts = visit|TX / 
		DDFM = BW /*M�thode pour le calcul des dls, option KR pour les dls de K-R*/ 
		ALPHA = 0.05 
		VCIRY /*Pour faire sortir les r�sidus mis-�-l'�chelle*/
		OUTPM = sortie OUTP = sortie2; 
		/* (INFLUENCE (ITER = 5 EST) Pour faire afficher les distances de Cook*/
	RANDOM intercept / SUBJECT = ID;
RUN; /*Le graphique sortie par d�faut par SAS nous indique que
certaines observations sont potentiellement influentes*/

DATA graphique;
	MERGE sortie (RENAME = (PRED = predm)) sortie2;
	IF ID IN (101, 102, 103, 104, 201, 202);
RUN;

PROC SORT DATA = graphique; BY VISIT TX ID; RUN;
PROC SGPLOT DATA = graphique;
	SERIES X = visit Y = predm / GROUP = TX LINEATTRS = (THICKNESS = 2);
	SERIES X = visit Y = pred / GROUP = ID LINEATTRS = (PATTERN = 2 COLOR = black);
	YAXIS MIN = 0 MAX = 15 INTEGER;
	XAXIS MIN = 1 MAX = 4 INTEGER;
RUN;

PROC SORT DATA = graphique; BY VISIT TX ID; RUN;
PROC SGPANEL DATA = graphique;
	PANELBY TX;
	SERIES X = visit Y = predm / GROUP = TX LINEATTRS = (THICKNESS = 2);
	SERIES X = visit Y = pred / GROUP = ID LINEATTRS = (PATTERN = 2 COLOR = black);
	ROWAXIS MIN = 0 MAX = 15 INTEGER;
	COLAXIS MIN = 1 MAX = 4 INTEGER;
RUN;

		

/*Mod�le mixte*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
	CLASS ID TX(REF = first);
	ID ID Visit TX; /*Pour dire � SAS comment identifier les obs*/
	MODEL counts = visit|TX / 
		DDFM = BW /*M�thode pour le calcul des dls, option KR pour les dls de K-R*/ 
		ALPHA = 0.05 
		VCIRY /*Pour faire sortir les r�sidus mis-�-l'�chelle*/
		OUTPM = sortie OUTP = sortie2; 
		/* (INFLUENCE (ITER = 5 EST) Pour faire afficher les distances de Cook*/
	RANDOM intercept visit / SUBJECT = ID TYPE = UN;

RUN; /*Le graphique sortie par d�faut par SAS nous indique que
certaines observations sont potentiellement influentes*/

DATA graphique;
	MERGE sortie (RENAME = (PRED = predm)) sortie2;
	IF ID IN (101, 102, 103, 104, 201, 202);
RUN;

PROC SORT DATA = graphique; BY TX VISIT ID; RUN;
PROC SGPANEL DATA = graphique;
	PANELBY TX;
	SERIES X = visit Y = predm / GROUP = TX LINEATTRS = (THICKNESS = 2);
	SERIES X = visit Y = pred / GROUP = ID LINEATTRS = (PATTERN = 2 COLOR = black);
	ROWAXIS MIN = 0 MAX = 15 INTEGER;
	COLAXIS MIN = 1 MAX = 4 INTEGER;
RUN;
	


/*Mod�le mixte*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
	CLASS ID TX(REF = first);
	ID ID Visit TX; /*Pour dire � SAS comment identifier les obs*/
	MODEL counts = visit|TX / 
		DDFM = KR /*M�thode pour le calcul des dls, option KR pour les dls de K-R*/ 
		ALPHA = 0.05 
		VCIRY /*Pour faire sortir les r�sidus mis-�-l'�chelle*/
		INFLUENCE (ITER = 5 EST) /*Pour faire afficher les distances de Cook
									les options ITER = 5 et EST ajoutent des
									diagnostiques similaires aux DFBETAS, mais peuvent
									rendre la proc�dure tr�s longue � ex�cuter.*/
		OUTPM = sortie OUTP = sortie2;
	RANDOM intercept visit / SUBJECT = ID TYPE = UN;
	ODS OUTPUT Influence = Influence; /*Enregistrer les diagnostiques d'influence*/
RUN; /*Le graphique sortie par d�faut par SAS nous indique que
certaines observations sont potentiellement influentes*/
DATA influence2;
	MERGE seizure2 influence;
	id_unique + 1;
	/* Calcul des valeurs absolues des DFbeta */
	parm3s = abs(parm3 + 0.08237)/4.04524;
RUN;
/* Graphique des valeurs absolues des DFbeta */
PROC SGPLOT DATA = influence2;
	SCATTER X = id_unique Y = parm3s;
RUN;

PROC SGPLOT DATA = influence2;
	SCATTER X = id_unique Y = parm3;
	REFLINE -0.08237;
RUN;

/* Calcul des valeurs pr�dites transform�es */
data sortie2;
  set sortie;
	predt = scaleddep - scaledresid;
run;
/* Diagramme de dispersion des r�sidus transform�s vs. valeurs pr�dites transform�es */
PROC SGPLOT DATA = sortie2;
	SCATTER X = predt Y = scaledresid;
run;



