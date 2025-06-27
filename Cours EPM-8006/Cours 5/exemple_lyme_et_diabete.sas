DATA lyme;
	DO i = 1 TO 500;
		Lyme = ranbin(74198, 1, 0.5);
		Score = 0.5 + Lyme*0.2 + rannor(471840)*0.15;
		IF score > 1 THEN score = 1;
	 	IF score < 0 THEN score = 0;
		IF score > 0.7 THEN diag = 1; ELSE diag = 0;
		IF score < 0.5 THEN diag2 = "< 0.5               ";
		ELSE IF score < 0.7 THEN diag2 = "0.5 < score < 0.7";
		ELSE diag2 = "> 0.7";
		test1 = 1;
		test4 = 0;
		IF score > 0.5 THEN test2 = 1;
		ELSE test2 = 0;
		OUTPUT;
	END;
RUN;

PROC MEANS DATA = lyme MIN MEDIAN MAX;
	CLASS lyme;
	VAR score;
RUN;

PROC FREQ DATA = lyme;
	TABLE diag*lyme;
RUN;

PROC FREQ DATA = lyme;
	TABLE diag2*lyme;
RUN;

PROC FREQ DATA = lyme;
	TABLE test1*lyme;
RUN;

PROC FREQ DATA = lyme;
	TABLE test2*lyme;
RUN;

PROC FREQ DATA = lyme;
	TABLE test4*lyme;
RUN;

PROC LOGISTIC DATA = lyme descending PLOT(ONLY) = ROC;
	MODEL lyme = score;
RUN;


PROC IMPORT DATAFILE = "C:\Users\etudiant\Documents\EPM-8006\donnees\fram12.csv"
	OUT = fram12
	REPLACE
	DBMS = CSV;
RUN;

PROC CONTENTS DATA = fram12; RUN;

DATA fram12b;
	SET fram12;
	KEEP sex age1 cursmoke1 BMI1 BMI_CAT glucose1 DIABETES2;
	WHERE diabetes1 = 0;
	IF BMI1 = . THEN BMI_CAT = "                        ";
	ELSE IF BMI1 <= 18.5 THEN BMI_CAT = "BMI<=18.5";
	ELSE IF BMI1 <= 25 THEN BMI_CAT = "18.5 < BMI <= 25";
	ELSE IF BMI1 <= 30 THEN BMI_CAT = "25 < BMI <= 30";
	ELSE IF BMI1 <= 35 THEN BMI_CAT = "30 < BMI <= 35";
	ELSE IF BMI1 <= 40 THEN BMI_CAT = "35 < BMI <= 40";
	ELSE BMI_CAT = "BMI > 40";
RUN;

PROC LOGISTIC DATA = fram12b DESCENDING PLOT(ONLY) = ROC;
	MODEL diabetes2 = bmi1 age1 sex glucose1 /CLPARM = WALD ctable;
	OUTPUT OUT = sortie XBETA = lin_pred;
RUN;

ods graphics on;

/* Affichage de la courbe ROC à partir des prédictions du modèle (utile pour comparer plusieurs modèles)
	Notez qu'il faut quand même un énoncé modèle, mais sans estimation avec l'option NOFIT*/
PROC LOGISTIC DATA = sortie DESCENDING PLOT(ONLY) = ROC;
	MODEL diabetes2 =  lin_pred / NOFIT;
	ROC "courbe ROC" lin_pred;
run;

/*Options CTABLE et PEVENT peuvent être utiles!!*/
