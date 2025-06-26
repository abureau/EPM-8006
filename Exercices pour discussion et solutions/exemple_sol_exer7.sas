/**************************************
* 7.1 EXEMPLE DE SOLUTION PROC GENMOD *
***************************************/


*Importation des donn�es;
DATA milk;
	INFILE "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2014\Donn�es\milk.data";
	INPUT diet cow week protein;
RUN;


*V�rifier que l'importation s'est bien d�roul�e;
PROC CONTENTS DATA = milk VARNUM; RUN;

PROC PRINT DATA = milk (OBS = 20); RUN;

*Statistiques descriptives;

*Je trace les courbes pour quelques vaches choisies "al�atoirement";
*L'objectif est de regarder la forme des donn�es sans surcharger le
graphique;
*Il s'agit d'un graphique que je fais pour moi, je ne l'ins�rerais
probablement pas dans un article;
PROC SGPLOT DATA = milk;
	WHERE cow in(1, 10, 20, 30, 40, 50, 60, 70);
	SERIES X = week Y = protein / GROUP = cow;
RUN;

*Je trace les courbes liss�es pour chaque di�te;
*J'aurais aussi pu relier entre elles les moyennes
calcul�es avec PROC MEANS tel que je l'avais fait
dans l'exemple sur les donn�es seizure;
PROC SGPANEL DATA = milk;
	PANELBY diet;
	SERIES X = week Y = protein / GROUP = COW;
	LOESS X = week Y = protein;
RUN; 
*Je constate qu'il y a beaucoup de variabilit� entre
les niveaux de prot�ines pour les vaches d'une m�me di�te.
Je constate aussi que la relation n'est pas lin�aire;
*Le graphique est un peu surcharg� avec les courbes de toutes
les vaches...;

*Le graphique suivant est moins charg�;
PROC SGPANEL DATA = milk;
	PANELBY diet;
	LOESS X = week Y = protein;
RUN; 
*Dans tous les cas, la quantit� de prot�ine chute rapidement au d�but, puis
reste relativement stable ou augmente selon la di�te.
On devrait exclure l'id�e de mod�liser une tendance lin�aire.
On pourrait utiliser du lin�aire par morceau ou mod�liser la relation
en consid�rant les semaines de fa�on cat�gorique;


*Moyennes et m�dianne par semaine par di�te.;
PROC TABULATE DATA = milk;
	CLASS diet week;
	VAR protein;
	TABLE diet, week*protein = ""*(MEAN = "Moy" MEDIAN = "Med");
RUN;

*Juste moyennes, car moyennes et m�dianes similaires.;
PROC TABULATE DATA = milk;
	CLASS diet week;
	VAR protein;
	TABLE diet, week*protein = ""*(MEAN = "Moy");
RUN;

*Produire un graphique des moyennes par semaine par traitement;
PROC SORT DATA = milk; BY diet week; RUN;
PROC MEANS DATA = milk NOPRINT;
	BY diet week;
	VAR protein;
	OUTPUT OUT = moy MEAN = m_protein;
RUN;

PROC SGPLOT DATA = moy;
	SERIES X = week Y = m_protein / GROUP = diet;
RUN;
*Le pic le plus bas est obtenu environ � la 4e semaine;

/*Puisque j'ai constat� que la relation est non lin�aire, j'ai
d�cid� d'inclure week dans l'�nonc� CLASS (cr�ation d'une indicatrice
pour chaque semaine).
Puisqu'il s'agit de donn�es continues, j'utilise une distribution de travail normale.
Puisqu'il s'agit de donn�es r�p�t�es, j'utilise une matrice de travail autor�gressive
d'ordre 1 (AR(1)).
�tant donn� l'�nonc� de la question qui est plut�t vague, il pourrait sembl�
appropri� d'utiliser une approche s�quentielle pour analyser les donn�es,
c'est-�-dire de d'abord tester si l'effet de la di�te varie dans le temps.
Si on constate que oui, on devra comparer les di�tes pour chaque semaine.
Si on constate que non, on pourra comparer la moyenne des di�tes pour
toutes les semaines combin�es.*/
/*Je trie les observations en ordre chronologique*/
PROC SORT DATA = milk; BY cow week; RUN;
PROC GENMOD DATA = milk;
	CLASS cow diet week;
	MODEL protein = diet|week / LINK = ID DIST = normal TYPE3 WALD; *J'utilise les options TYPE3 et WALD pour
										obtenir un tableau d'analyse de la variance. Je tableau me donne le
										r�sultat du test d'hypoth�ses simultan�es sur les param�tres d'interaction.;
	REPEATED SUBJECT = cow / TYPE = AR(1); *Le type AR(1) semble appropri� dans ce cas;
	SLICE diet*week / DIFF SLICEBY = week;
	OUTPUT OUT = resid DFBETA = _all_  resraw = resid COOKSD = cook;
RUN;
*Les tests de types 3 nous indiquent que l'effet de la di�te varie dans le temps
(diet*week 36 74.38 0.0002). Je dois donc comparer mes moyennes entre elles pour
chaque semaine. Pour ce faire, j'utilise l'�nonc� SLICE.;
*Puisqu'on est dans un contexte explicatif, l'id�al serait de faire sortir les
dfbetas pour diagnostiquer les donn�es influentes, mais il y a beaucoup
de param�tres... Je vais plut�t regarder le distances de Cook et les r�sidus.;


PROC BOXPLOT DATA = resid;
	PLOT resid*diet / BOXSTYLE = SCHEMATIC;
RUN; QUIT;

PROC SORT DATA = resid; BY week; RUN;
PROC BOXPLOT DATA = resid;
	PLOT resid*week / BOXSTYLE = SCHEMATIC;
RUN; QUIT;
*Les r�sidus semblent corrects;

/*Je cr�e un identifiant unique pour
faire un graphique pour les distances de Cook.*/
DATA resid2;
	SET resid;
	id + 1;
RUN;

*Donn�es influentes ou extr�mes;
PROC SORT DATA = resid; BY DESCENDING cook; RUN;
PROC PRINT DATA = resid (OBS = 20); VAR cook cow week diet protein resid; RUN;
PROC SGPLOT DATA = resid2;
	NEEDLE X = id Y = cook;
RUN;
*Il ne semble pas y avoir de donn�es influentes;

/*Interpr�tation: 
Nos analyses indiquent que le contenu en prot�ines du lait de vache varie en fonction de la di�te et du temps
�coul� depuis le v�lage. De plus, il semble que l'effet des di�tes varie dans le temps. Le contenu en prot�ines du lait
a ainsi �t� compar� entre les di�tes � chaque semaine. Les r�sultats obtenus pour ces analyses d�montrent
la sup�riorit� de la di�te � l'orge par rapport � la di�te au lupin. En effet, le contenu en prot�ine du lait des vaches
nourries � l'orge est sup�rieur � celui des vaches nourries au lupin pour les semaines 2, 3, 5 ainsi que 7 � 19.
Les comparaisons par semaine de la di�te � l'orge vs la di�te m�lang�e ou de la di�te m�lang�e vs la di�te au lupin
sont cependant plus nuanc�es en raison d'un manque de puissance statistique.*/



/**********Approche de r�gressoin par morceau - plus avanc�***************/
/*Cette partie de programme n'est donn�e qu'� titre informatif.*/
/*On va ajuster un mod�le de Y en fonction de diet et de week
o� on va supposer une relation lin�aire par morceau entre diet*week et
Y. Un premi�re pente correspondra � la relation pour week = 1 jusqu'� week = 4,
l'autre pente correspondra � la relation pour week = 5 � week = 19.

Math�matiquement, le mod�le a la forme suivante :
E[Y|diet, week]  = b0 + b1*week + b2*diet_1 + b3*diete_2 + b4*diet_1*week + b5*diet_2*week
					+ b6*max(0, week - 4) + b7*diet_1*max(0, week - 4) + b8*diet_2*max(0, week - 4).

Ici, b6 � b8 permettent de repr�senter le changement dans la pente de Y apr�s la 4e semaine
pour chacune des di�tes. En effet, remarquez que pour les semaines 1 � 4, b6, b7 et b8 seront
tous multipli�s par 0, car max(0, week - 4) = 0. Ainsi, par exemple, la pente de Y en fonction
de week pour la di�te 1 pour ces semaines sera b1 + b4 (pour la di�te 1 et pour les semaines 1 � 4,
lorsque week augmente de 1 unit�, Y augmente en moyenne de b1 + b4).
Pour les semaines suivantes, la pente associ�e � la di�te 1 sera plut�t de b1 + b4 + b6 + b7.
Ainsi, b6 + b7 correspondent au changement de pente pour ces di�tes.*/ 

/*On va devoir d'abord cr�er la nouvelle variable pour max(0, week - 4)*/

DATA milk2;
	SET milk;
	max4 = max(0, week - 4);
RUN;

PROC SORT DATA = milk2; BY cow week; RUN;
PROC GENMOD DATA = milk2;
	CLASS cow diet / PARAM = REF; /*Plus facile de construire des contrastes avec PARAM = REF!*/
	MODEL protein = diet week diet*week max4 diet*max4 / LINK = ID DIST = normal TYPE3 WALD;
	REPEATED SUBJECT = cow / TYPE = AR(1); *Le type AR(1) semble appropri� dans ce cas;
	OUTPUT OUT = resid DFBETA = _all_  resraw = resid COOKSD = cook P = predit;
	/*Est-ce que l'effet de la di�te varie dans le temps ?*/
	CONTRAST "Interaction week*diet" week*diet 1 0, week*diet 0 1, diet*max4 1 0, diet*max4 0 1 / WALD;
	/*La pente change-t-elle apr�s la semaine 4?*/
	CONTRAST "Changement de pente" max4 1, diet*max4 1 0, diet*max4 0 1 / WALD;
RUN;
/*Cette fois, on ne peut pas rejeter que l'effet de la di�te ne change pas dans le temps
(Interaction week*diet 4 4.41 0.3538 Wald). Toutefois, les r�sultats confirment qu'il y
a un changement de pente � la semaine 4 (Changement de pente 3 127.89 <.0001 Wald).
Puisque l'effet de la di�te ne varie pas dans le temps, on pourrait simplement
comparer les moyennes sur toutes les semaines entre elles. Malheureusement,
on ne peut pas utiliser LSMEANS avec PARAM = REF...*/



PROC SORT DATA = milk2; BY cow week; RUN;
PROC GENMOD DATA = milk2;
	CLASS cow diet / PARAM = GLM; 
	MODEL protein = diet week diet*week max4 diet*max4 / LINK = ID DIST = normal TYPE3 WALD;
	REPEATED SUBJECT = cow / TYPE = AR(1); *Le type AR(1) semble appropri� dans ce cas;
	LSMEANS diet / DIFF CL; 
	OUTPUT OUT = resid DFBETA = _all_  resraw = resid COOKSD = cook P = predit;
	/*Plus difficile de construire le test d'hypoth�se simultan� avec PARAM = GLM...
	pour obtenir les m�mes r�sultats!
	Une strat�gie serait de de calculer les tests avec PARAM = REF
	et obtenir les LSMEANS avec PARAM = GLM!*/

	/*Est-ce que l'effet de la di�te varie dans le temps ?*/
	CONTRAST "Int. diet*week" diet*week 1 -1  0, diet*week 1  0 -1,
							  diet*week 1 -1  0  diet*max4 1 -1  0,
							  diet*week 1  0 -1  diet*max4 1  0 -1 / WALD;
	/*La pente change-t-elle apr�s la semaine 4?*/
	CONTRAST "diet*week" max4 1 diet*max4 1 0 0, max4 1 diet*max4 0 1 0, max4 1 diet*max4 0 0 1 / WALD;
	/*Remarquez que j'obtiens exactement les m�mes r�sultats dans mes �nonc�s CONTRAST avec PARAM = GLM
	qu'avec PARAM = REF*/
RUN;

/*
En moyenne, la di�te � l'orge a un contenu en prot�ine plus �lev� que la di�te m�lang�e
(diff�rence de moyenne = 0.10, IC � 95%: 0.01 � 0.19) et que la di�te au lupin
(diff�rence de moyenne = 0.21, IC � 95%: 0.11 � 0.32). La di�te m�lang� est par ailleurs
sup�rieure � la di�te au lupin (diff�rence de moyenne = 0.11, IC � 95%: 0.02 � 0.20).*/


PROC SORT DATA = resid; BY diet week; RUN;
PROC MEANS DATA = resid NOPRINT;
	BY diet week;
	VAR predit;
	OUTPUT OUT = moyennes MEAN = ;
RUN;

/*Graphique des valeurs pr�dites*/
PROC SGPLOT DATA = moyennes;
	SERIES Y = predit X = week / GROUP = diet;
RUN;

/*Tendance observ�es (pointill�) et pr�dite (ligne pleine) superpos�es*/
PROC SGPLOT DATA = resid;
	SERIES Y = predit X = week / GROUP = diet;
	LOESS Y = protein X = week / GROUP = diet NOMARKERS LINEATTRS = (PATTERN = 2);
RUN;
/*Ce n'est pas un mod�le parfait, mais il semble faire une bonne approximation sans n�cessiter
trop de param�tres*/


**********************************D�fi :

*Le d�fi est tr�s difficile � relever avec
les proc�dures que nous avons vues jusqu'� m'aintenant...

- Je vais utiliser une strat�gie par imputation multiple
- On va d'abord devoir cr�er des nouvelles lignes;


*Je veux savoir quels sont les num�ros de vache par di�te.;
PROC FREQ DATA = milk;
	TABLE cow*diet;
RUN;

*cr�ation d'un jeu de donn�es en format large pour l'imputation;
*d'abord cr�ation d'un jeu par semaine;
DATA week1 week2 week3 week4 week5 week6
	 week7 week8 week9 week10 week11 week12
	 week13 week14 week15 week16 week17 week18 week19;
	SET milk;
	IF week = 1 THEN DO;
		OUTPUT week1;
	END;
	IF week = 2 THEN DO;
		OUTPUT week2;
	END;
	IF week = 3 THEN DO;
		OUTPUT week3;
	END;
	IF week = 4 THEN DO;
		OUTPUT week4;
	END;
	IF week = 5 THEN DO;
		OUTPUT week5;
	END;
	IF week = 6 THEN DO;
		OUTPUT week6;
	END;
	IF week = 7 THEN DO;
		OUTPUT week7;
	END;
	IF week = 8 THEN DO;
		OUTPUT week8;
	END;
	IF week = 9 THEN DO;
		OUTPUT week9;
	END;
	IF week = 10 THEN DO;
		OUTPUT week10;
	END;
	IF week = 11 THEN DO;
		OUTPUT week11;
	END;
	IF week = 12 THEN DO;
		OUTPUT week12;
	END;
	IF week = 13 THEN DO;
		OUTPUT week13;
	END;
	IF week = 14 THEN DO;
		OUTPUT week14;
	END;
	IF week = 15 THEN DO;
		OUTPUT week15;
	END;
	IF week = 16 THEN DO;
		OUTPUT week16;
	END;
	IF week = 17 THEN DO;
		OUTPUT week17;
	END;
	IF week = 18 THEN DO;
		OUTPUT week18;
	END;
	IF week = 19 THEN DO;
		OUTPUT week19;
	END;
	DROP week;
RUN;

DATA large;
	MERGE week1 (RENAME = (protein = protein1)) 
		  week2 (RENAME = (protein = protein2))
		  week3 (RENAME = (protein = protein3))
		  week4 (RENAME = (protein = protein4))
		  week5 (RENAME = (protein = protein5))
		  week6 (RENAME = (protein = protein6))
		  week7 (RENAME = (protein = protein7))
		  week8 (RENAME = (protein = protein8))
		  week9 (RENAME = (protein = protein9))
		  week10 (RENAME = (protein = protein10))
		  week11 (RENAME = (protein = protein11))
		  week12 (RENAME = (protein = protein12))
		  week13 (RENAME = (protein = protein13))
		  week14 (RENAME = (protein = protein14))
		  week15 (RENAME = (protein = protein15))
		  week16 (RENAME = (protein = protein16))
		  week17 (RENAME = (protein = protein17))
		  week18 (RENAME = (protein = protein18))
		  week19 (RENAME = (protein = protein19));
	IF diet = 1 THEN diet1 = 1; ELSE diet1 = 0;
	IF diet = 2 THEN diet2 = 1; ELSE diet2 = 0;
	BY cow;
RUN;

/*V�rifier le format du fichier*/
PROC PRINT DATA = large (obs = 5); RUN;


PROC MI DATA = large NIMPUTE = 0;
	VAR diet1 diet2 protein1-protein19;
RUN;
/*Environ 47% des lignes sont compl�tes et 53% sont incompl�tes*/

/*Note : l'approche bay�sienne bas�e sur l'hypoth�se de normalit�
multivari�e se pr�te bien dans ce cas, puisque toutes les variables sont
contiues.*/
PROC MI DATA = large NIMPUTE = 53 OUT = large_imp SEED = 4791847;
	VAR diet1 diet2 protein1-protein19;
	MCMC NITER = 500
		 NBITER = 2000
	     PLOTS = (ALL ACF(NLAG = 1000));
	EM MAXITER = 500;
RUN;
/*Il est tr�s difficile d'obtenir de bons graphiques d'auto-corr�lation
pour les variables prot�ines 18-19, car il y a beaucoup de donn�es manquantes...*/

DATA long;
	SET large_imp;
	DO week = 1 TO 19;
		IF week = 1 THEN protein = protein1;
		IF week = 2 THEN protein = protein2;
		IF week = 3 THEN protein = protein3;
		IF week = 4 THEN protein = protein4;
		IF week = 5 THEN protein = protein5;
		IF week = 6 THEN protein = protein6;
		IF week = 7 THEN protein = protein7;
		IF week = 8 THEN protein = protein8;
		IF week = 9 THEN protein = protein9;
		IF week = 10 THEN protein = protein10;
		IF week = 11 THEN protein = protein11;
		IF week = 12 THEN protein = protein12;
		IF week = 13 THEN protein = protein13;
		IF week = 14 THEN protein = protein14;
		IF week = 15 THEN protein = protein15;
		IF week = 16 THEN protein = protein16;
		IF week = 17 THEN protein = protein17;
		IF week = 18 THEN protein = protein18;
		IF week = 19 THEN protein = protein19;
		OUTPUT;
	END;
RUN;
		
PROC SORT DATA = long; BY _imputation_ cow week; RUN;


/*Il est difficile d'utiliser l'approche s�quentielle 
avec l'imputation multiple... Supposons qu'on veut simplement
comparer les moyennes globales entre les di�tes pour simplifier*/

/*Je vais d'abord rouler une fois la proc�dure pour la premi�re imputation
en utilisant ODS TRACE ON; et ODS TRACE OFF; pour conna�tre le nom
que SAS donne au tableau des LSMEANS (se trouve dans le log)*/
ODS TRACE ON;
PROC GENMOD DATA = long;
	WHERE _imputation_ = 1;
	CLASS cow diet week;
	MODEL protein = diet|week / LINK = ID DIST = normal TYPE3 WALD;
	REPEATED SUBJECT = cow / TYPE = AR(1); *Le type AR(1) semble appropri� dans ce cas;
	LSMEANS diet / DIFF;
RUN;
ODS TRACE OFF;
/*
Ce tableau se donne diffs :

Output Added:
-------------
Name:       Diffs
Label:      diet Diffs
Template:   Stat.Genmod.Diffs
Path:       Genmod.Diffs
-------------
*/

/*Je vais maintenant rouler mes analyses par imputation
en enregistrant les sorties diffs avec ODS OUTPUT.
J'utilise ODS SELECT pour que la sortie ne contienne que
ce tableau (pour raccourcir les sorties)*/
PROC GENMOD DATA = long;
	BY _imputation_;
	CLASS cow diet week;
	MODEL protein = diet|week / LINK = ID DIST = normal TYPE3 WALD;
	REPEATED SUBJECT = cow / TYPE = AR(1); *Le type AR(1) semble appropri� dans ce cas;
	LSMEANS diet / DIFF;
	ODS OUTPUT Diffs = Diffs;
	ODS SELECT Diffs;
RUN;

/*Il est un peu difficile de combiner les
r�sultats de LSMEANS avec PROC MIANALYZE.
Je m'en suis sorti en cr�ant une nouvelle variable
qui indiquera quelle diff�rence de moyenne est consid�r�e
(1 vs 2, 1 vs 3 ou 2 vs 3) et j'ex�cute s�par�ment
MIANALYZE pour chaque diff�rence. Je vais simplement
donner � MIANALYZE les diff�rences de moyennes � combiner
avec leur erreur type.*/
DATA diffs2;
	SET diffs;
	ef = compress(diet||_diet);
RUN;

PROC SORT DATA = diffs2; BY ef; RUN;
PROC MIANALYZE DATA = diffs2;
	BY ef;
	MODELEFFECTS estimate;
	STDERR stderr;
RUN;

/* Sans imputation :
PROC GENMOD DATA = milk;
	CLASS cow diet week;
	MODEL protein = diet|week / LINK = ID DIST = normal TYPE3 WALD;
	REPEATED SUBJECT = cow / TYPE = AR(1); *Le type AR(1) semble appropri� dans ce cas;
	LSMEANS diet / DIFF;
RUN;

Differences of diet Least Squares Means 
diet _diet Estimate Standard Error z Value Pr > |z| 
1 2 0.1039 0.04768 2.18 0.0294 
1 3 0.2259 0.05371 4.21 <.0001 
2 3 0.1221 0.04375 2.79 0.0053 

Avec imputation : 
Parameter Estimate Std Error 95% Confidence Limits DF Minimum Maximum Theta0 t for H0:
Parameter=Theta0 Pr > |t| 
estimate 0.112086 0.046032 0.021860 0.202312 22436 0.088659 0.132189 0 2.43 0.0149 
estimate 0.221313 0.053716 0.116026 0.326601 24824 0.192615 0.248007 0 4.12 <.0001 
estimate 0.109227 0.044465 0.022073 0.196381 22599 0.089237 0.129828 0 2.46 0.0140 

Les r�sultats sont donc similaires!
*/




/*************************************
* 7.2 EXEMPLE DE SOLUTION PROC MIXED *
*************************************/

*Importation des donn�es;
DATA milk;
	INFILE "C:\Users\detal9\Dropbox\Travail\Cours\EPM8006\Automne 2014\Donn�es\milk.data";
	INPUT diet cow week protein;
RUN;


*V�rifier que l'importation s'est bien d�roul�e;
PROC CONTENTS DATA = milk VARNUM; RUN;

PROC PRINT DATA = milk (OBS = 20); RUN;


*Statistiques descriptives;

*Je trace les courbes pour quelques vaches choisies "al�atoirement";
PROC SGPLOT DATA = milk;
	WHERE cow in(1, 10, 20, 30, 40, 50, 60, 70);
	SERIES X = week Y = protein / GROUP = cow;
RUN;

*Je trace les courbes liss�es pour chaque di�te;
PROC SGPANEL DATA = milk;
	PANELBY diet;
	SERIES X = week Y = protein / GROUP = COW;
	LOESS X = week Y = protein;
RUN; 

PROC SGPANEL DATA = milk;
	PANELBY diet;
	LOESS X = week Y = protein;
RUN; 
*Dans tous les cas, la quantit� de prot�ine chute rapidement au d�but, puis
reste relativement stable ou augmente selon la di�te.
On devrait exclure l'id�e de mod�liser une tendance lin�aire.
On pourrait utiliser du lin�aire par morceau ou autre;


*Moyennes et m�dianne par semaine par di�te.;
PROC TABULATE DATA = milk;
	CLASS diet week;
	VAR protein;
	TABLE diet, week*protein = ""*(MEAN = "Moy" MEDIAN = "Med");
RUN;

*Juste moyennes, car moyennes et m�dianes similaires.;
PROC TABULATE DATA = milk;
	CLASS diet week;
	VAR protein;
	TABLE diet, week*protein = ""*(MEAN = "Moy");
RUN;

*Produire un graphique des moyennes par semaine par traitement;
PROC SORT DATA = milk; BY diet week; RUN;
PROC MEANS DATA = milk NOPRINT;
	BY diet week;
	VAR protein;
	OUTPUT OUT = moy MEAN = m_protein;
RUN;

PROC SGPLOT DATA = moy;
	SERIES X = week Y = m_protein / GROUP = diet;
RUN;
*Le pic le plus bas est obtenu � la 4e semaine;

/*�tant donn� les graphiques observ�s, ce n'est pas tr�s sens�
de suppos� une relation lin�aire entre le temps et la quantit� de
prot�ines. Cat�goriser les semaines est donc une approche simple,
bien qu'elle exige beaucoup de param�tres.
�tant donn� que j'ai des mesures longitudinales �galement espac�es,
une approche tr�s intuitive pour mod�liser la corr�lation entre
les mesures r�p�t�es est d'utiliser une forme AR(1) pour les erreurs
r�siduelles associ�es � une vache donn�e.
Je vais tout de m�me essayer plusieurs mod�lisation, les comparer par
rapport au BIC et interpr�ter l'analyse avec le meilleur ajustement
selon le BIC.
 - AR
 - ARH(1) (m�me chose que AR(1), mais avec des variances pouvant varier selon la semaine)
 - CS <=> ordonn�e � l'origine al�atoire
 - CSH (m�me chose que CS, mais avec des variances pouvant varier selon la semaine)
Et comparer l'ajustement en fonction du BIC.
Je ne testerai pas UN, parce que ce serait trop lourd (19*20/2 = 190 param�tres � estimer!)

Ici, supposer une pente lin�aire al�atoire selon la vache n'aurait pas beaucoup de sens 
puisque la relation entre les prot�ines et les semaines ne semble pas du tout lin�aire.
Ce ne serait techniquement pas possible de supposer une ordonn�e � l'origine al�atoire
pour la vache et une effet al�atoire de la semaine cat�gorique
pour la vache, car on aurait alors autant de param�tres al�atoires qu'il y a d'observation
par vache. 

On pourrait cependant utiliser une ordonn�e � l'origine al�atoire, une
pente al�atoire et un terme quadratique al�atoire. Il faudrait alors cr�er une variable
week_continue qu'on ne mettrait pas dans l'�nonc� CLASS, voir ci-dessous.*/

 
/*Comparaison de diff�rents mod�les*/
/*AR(1)*/
PROC SORT DATA = milk; BY cow week; RUN;
PROC MIXED DATA = milk;
	CLASS cow diet week;
	MODEL protein = diet|week / VCIRY DDFM = BW;
	REPEATED / SUBJECT = cow TYPE = AR(1); 
RUN; /*BIC = 148.8*/

/*ARH(1)*/
PROC SORT DATA = milk; BY cow week; RUN;
PROC MIXED DATA = milk;
	CLASS cow diet week;
	MODEL protein = diet|week / VCIRY DDFM = BW;
	REPEATED / SUBJECT = cow TYPE = ARH(1); 
RUN; /*BIC = 155.3*/

/*CS*/
PROC MIXED DATA = milk;
	CLASS cow diet week;
	MODEL protein = diet|week / VCIRY DDFM = BW;
	REPEATED / SUBJECT = cow TYPE = CS; 
RUN; /*BIC = 436.3*/

/*CSH*/
PROC MIXED DATA = milk;
	CLASS cow diet week;
	MODEL protein = diet|week / VCIRY DDFM = BW;
	REPEATED / SUBJECT = cow TYPE = CSH; 
RUN; /*BIC = 457.4 */

/*Ordonn�e, week et week^2 al�atoires*/
DATA milk_cont;
	SET milk;
	week_continue = week;
	week_continue2 = week**2;
RUN;

PROC MIXED DATA = milk_cont;
	CLASS cow diet week;
	MODEL protein = diet|week / VCIRY DDFM = BW;
	RANDOM intercept week_continue week_continue2 / SUBJECT = cow TYPE = UN;
RUN; /*BIC = 143.2 */


/*Conclusion: ordonn�e, week et week2 al�atoire est la structure fonctionnant le mieux!*/

PROC SORT DATA = milk_cont; BY cow week; RUN;
PROC MIXED DATA = milk_cont;
	CLASS cow diet week;
	MODEL protein = diet|week / VCIRY DDFM = BW OUTPM = Sortie INFLUENCE (ITER = 5 EST);
	RANDOM intercept week_continue week_continue2 / SUBJECT = cow TYPE = UN;
	LSMEANS diet / DIFF CL;
	SLICE diet*week / DIFF SLICEBY = week;
	ODS OUTPUT Influence = INFLUENCE;*Pour sortir les distances de Cook dans un fichier;
RUN; 
/*Un peu long � rouler en raison des diagnostiques d'influence*/
DATA sortie2;
	MERGE sortie influence;
	id + 1; *Je cr�e un identifiant unique pour mes diagnostiques d'influence.;
RUN;

*Les tests de types 3 nous indiquent qu'on ne peut pas rejeter l'hypoth�se
que l'effet de la di�te ne varie pas selon les semaines. De fa�on globale,
la di�te 1 est sup�rieure aux 2 autres et la 2 sup�rieure � la di�te 3.;
/*Remarquez les DLs au d�nominateur :

Type 3 Tests of Fixed Effects 
Effect   Num DF Den DF   F Value Pr > F 
diet          2   76        7.93 0.0007 
week         18 1204       25.66 <.0001 
diet*week    36 1204        0.79 0.8063 


Notre tableau d'ANOVA:
Diet 2
Erreur 1 = 79 (vaches) - 2 (dl pour diet) - 1 = 76
--------------------------------------------------
Week        18
Diet*week   2*18 = 36 (dl de diet * dl de week)
Erreur 2 = 1337 obs - 36 (dl de diet*week) - 18 (dl de week) - 76 (dl de l'erreur 1) - 2 (dl de diet) - 1 = 1204

La somme des dls = 2 + 76 + 18 + 36 + 1204 = 1336, soit n - 1*/


/*V�rification des hypoth�ses*/
/*Les graphiques de la sortie de PROC MIXED sugg�raient qu'on a la normalit�
et l'homosc�dasticit�. Il y aurait peut-�tre une observation un peu influente.
Je vais tout de m�me tracer quelques graphiques
des r�sidus selon la semaine et selon la di�te pour explorer davantage et 
pour illustrer comment faire.*/ 
PROC BOXPLOT DATA = Sortie;
	PLOT scaledresid*diet / BOXSTYLE = SCHEMATIC;
RUN; QUIT;

PROC SORT DATA = Sortie; BY week; RUN;
PROC BOXPLOT DATA = Sortie;
	PLOT scaledresid*week / BOXSTYLE = SCHEMATIC;
RUN; QUIT;
*Les r�sidus semblent corrects;


PROC SORT DATA = sortie2; BY DESCENDING CookD; RUN;
PROC PRINT DATA = sortie2 (OBS = 20); RUN;
PROC SGPLOT DATA = sortie2;
	NEEDLE X = id Y = CookD;
RUN;
/*Il y a peut-�tre une observation influente. On pourrait essayer de la retirer en
guise d'analyse de sensibilit�*/


/*Interpr�tation: 
Nos analyses indiquent que le contenu en prot�ines du lait de vache varie en fonction de la di�te et du temps
�coul� depuis le v�lage. Cependant, les analyses effectu�es ne permettent pas d'identifier une variation dans
l'effet de la di�te sur le contenu en prot�ines en fonction du temps �coul� depuis le v�lage. 
En moyenne, le contenu en prot�ine du lait des vaches nourries � l'orge est sup�rieur � celui des vaches nourries 
au lupin (0.22 IC � 95%: 0.11 � 0.34) ou avec un m�lange d'orge et de lupin (0.11, IC � 95%: 0.00, 0.23). 
Les vaches nourries selon le m�lange donnent �galement un lait plus riche en prot�ine
que les vaches nourries au lupin (0.11, IC � 95%: -0.00, 0.22).

Le contenu en prot�ines du lait a �galement �t� compar� � chaque semaine. Les r�sultats obtenus pour ces analyses confirment
la sup�riorit� de la di�te � l'orge par rapport � la di�te au lupin. En effet, le contenu en prot�ine du lait des vaches nourries � l'orge
est sup�rieur � celui des vaches nourries au lupin pour les semaines 2, 5 ainsi que 7 � 17. Les comparaisons par
semaine de la di�te � l'orge vs la di�te m�lang�e ou de la di�te m�lang�e vs la di�te au lupin sont cependant plus nuanc�s
en raison d'un manque de puissance statistique.*/

/*Remarquons en conclusion que les r�sultats avec GENMOD avec ou sans imputation ainsi que ceux avec PROC MIXED 
sont tr�s similaires.*/

**********************************D�fi :

*�tant donn� que les mod�les mixtes sont robustes aux donn�es MAR, il n'y
a rien de plus � faire!;


