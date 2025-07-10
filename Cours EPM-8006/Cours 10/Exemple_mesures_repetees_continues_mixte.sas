/*Nous reanalysons les donnees du progabide
en considerant une strategie differente d'analyse.
Au lieu de modeliser le nombre de crise, on modelisera
le rapport du nombre de crise par semaine pour une periode
donnee vs le nombre de crise par semaine pre-traitement.*/


/*Lecture des donnees*/
DATA seizure;
    INFILE "/workspaces/workspace/Données EPM-8006/seizure.data";
    INPUT ID Counts Visit TX Age Weeks;
RUN;

/*Afficher les donnees*/
PROC PRINT DATA = seizure (OBS = 10); RUN;

/*Creer un jeu de donnees avec les valeurs au depart
placee dans des variables separees*/
DATA baseline;
    SET seizure;
    WHERE Visit = 0;
    Counts0 = counts;
    Age0 = Age;
    KEEP ID Counts0 Age0;
RUN;

PROC SORT DATA = baseline; BY id; RUN;
PROC SORT DATA = seizure; BY id; RUN;

/*Pour essayer de reduire la variance, je decide d'analyser 
une variable issue transformee correspondant au nombre de crises
par semaine post-traitement divise par le nombre de crises par semaines
pre-traitement. Une valeur > 1 correspond donc a une augmentation du
nombre de crises par rapport a la situation pre-traitement, alors
qu'une valeur < 1 correspond a une diminution du nombre de crises.
L'interpretation sera plus lourde, mais permet d'incorporer directement
dans l'issue le nombre de crises pre-traitement.*/

DATA seizure2;
    MERGE seizure baseline;
    BY ID;
    IF Visit = 0 THEN DELETE;
    RELCount = (Counts/2)/(Counts0/8);
RUN;

PROC PRINT DATA = seizure2 (OBS = 10); RUN;

/*Effectuer quelques statistiques descriptives / graphiques*/
PROC SORT DATA = seizure2; BY visit TX; RUN;
PROC MEANS DATA = seizure2 NOPRINT;
    BY visit TX;
    VAR RELCount;
    OUTPUT OUT = stat_desc MEAN = m_counts;
RUN;

DATA stat_desc2;
    MERGE seizure2 stat_desc;
    BY visit TX;
RUN;

PROC SGPLOT DATA = stat_desc2;
    SCATTER X = visit Y = RELCount / GROUP = TX;
    SERIES X = visit Y = m_counts / GROUP = TX;
RUN;

PROC TABULATE DATA = seizure2;
    CLASS VISIT TX;
    VAR RELCount;
    TABLE TX, visit*RELCount = ""*(MEAN = "Moy" MEDIAN = "Med" STD = "É-T");
RUN;


/*Modele mixte*/
PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2; /*On peut ajouter ici une option METHOD = ML
                            si on veut utiliser la methode ML*/
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit TX; /*Pour dire a SAS comment identifier les obs*/
    MODEL RelCount = visit|TX / 
        DDFM = BW /*Methode pour le calcul des dls, option KR pour les dls de K-R*/ 
        ALPHA = 0.05 
        VCIRY /*Pour faire sortir les residus mis-a-l'echelle*/
        OUTPM = sortie /*Fichier contenant les residus mis-a-l'échelle*/
        INFLUENCE (ITER = 5 EST); /*Pour faire afficher les distances de Cook
                                    les options ITER = 5 et EST ajoutent des
                                    diagnostiques similaires aux DFBETAS, mais peuvent
                                    rendre la procedure tres longue a executer.*/
    REPEATED visit / SUBJECT = ID TYPE = AR(1); 
    LSMEANS TX*Visit /CL;
    LSMEANS TX /DIFF CL;
    SLICE TX*VISIT / DIFF SLICEBY = visit ALPHA = 0.05;
    ODS OUTPUT Influence = Influence;
RUN; /*Le graphique sortie par defaut par SAS nous indique que
certaines observations sont potentiellement influentes*/

DATA influence2;
    MERGE seizure2 influence;
    id_unique + 1;
RUN;

/*** Verification des hypotheses ***/
/* Normalite */
PROC UNIVARIATE DATA = sortie;
    VAR scaledresid;
    QQPLOT scaledresid / NORMAL(MU = 0 SIGMA = 1);
RUN; * Le graphique montre des problemes, mais hypothese
      pas vraiment importante;

/* Homoscedasticite */
PROC MEANS DATA = sortie STD;
    CLASS visit;
    VAR scaledresid;
RUN;
PROC MEANS DATA = sortie STD;
    CLASS tx;
    VAR scaledresid;
RUN;
PROC MEANS DATA = sortie STD;
    CLASS tx visit;
    VAR scaledresid;
RUN;
PROC SGPLOT DATA = sortie;
    SCATTER Y = scaledresid X = pred;
RUN;
* Les resultats montrent des problemes au niveau
de l'homoscedasticite. Les variances ne semblent
pas constantes.;


/* Donnees influentes */
PROC SORT DATA = influence2; BY DESCENDING cookD; RUN;
PROC PRINT DATA = influence2 (OBS = 20);
    VAR ID visit TX RelCount CookD;
RUN;
PROC SGPLOT DATA = influence2;
    NEEDLE X = id_unique Y = cookD;
RUN;

* Les parametres 6, 8, 9 et 10 sont les coefficients
  associes au traitement.
  Les graphiques ci-dessous montrent le coefficient
  estime quand une observation est retiree. 
  Refline au coefficient estime avec toutes les donnees;
PROC SGPLOT DATA = influence2;
    SCATTER X = id_unique Y = Parm6;
    REFLINE -0.3554;
RUN;

PROC SGPLOT DATA = influence2;
    SCATTER X = id_unique Y = Parm8;
    REFLINE -0.1079;
RUN;

PROC SGPLOT DATA = influence2;
    SCATTER X = id_unique Y = Parm9;
    REFLINE 0.1662;
RUN;

PROC SGPLOT DATA = influence2;
    SCATTER X = id_unique Y = Parm10;
    REFLINE 0.1516;
RUN;

/* Relation residuelle - aucune hypothese particuliere effectuee */
/* Si on avait une variable pour laquelle on supposait une relation
  lineaire, on pourrait faire un graphique du genre
PROC SGPLOT DATA = sortie;
    SCATTER X = visit Y = scaledresid;
    LOESS X = visit Y = scaledresid / CLM = "95CI" CLMTRANSPARENCY = 0.5;
RUN;
*/


/*Conclusion:
Les resultats obtenus suggerent que le progabide permet
une diminution du risque d'epilepsie au dela de l'effet des traitements
de chimiotherapie seuls.

En effet, sur l'ensemble des quatre periodes, le nombre de crise
par semaine pour les sujets recevant le traitement est 13% moins grand
qu'avant le traitement (IC a 95%: -33%, +7%) alors que le nombre
de crise par semaine chez les sujets recevant le placebo augmente
de 17% (IC a 95%: -4%, + 39%). Les donnees sont ainsi compatibles
avec une diminution relative du nombre de crises par semaine chez
les sujets traites comparativement aux sujets non-traites
(diff = -30%, IC a 95%: -60%, -1%). 

Les etudes futures concernant l'effet du progabide pourraient, entre autres,
tenter de mieux qualifier les variations temporelles en etudiant les sujets
sur une plus longue periode. Il serait par ailleurs interessant de
determiner si le progabide a un effet comparable dans d'autres populations
et si son effet varie selon divers autres facteurs (e.g. sexe, age,
severite de la maladie). Les effets secondaires du progabide n'ont
pas non plus ete etudies dans cette etude.*/ 





/*Quelques autres options de modelisation:

1. Pour modeliser la dependance:

1.1 Ordonnee a l'origine aleatoire pour le sujet 
    (equivalent a une correlation CS) :
RANDOM intercept / SUBJECT = id; 

1.2 Ordonnée aleatoire et effet aleatoire de visite pour le sujet :

RANDOM intercept visit / SUBJECT = id TYPE = UN; 

1.3 Type UN pour les erreurs :
REPEATED visit / SUBJECT = id TYPE = UN;

Les quatres options (ces 3 plus celle utilisee) pourraient etre
comparees avec le AIC ou le BIC pour choisir ce qui s'ajuste
le mieux aux donnees.


2. Pour reduire la variabilite :

Considerer ensemble les periode 1+2 et 3+4 et effectuer une moyenne.
On aurait alors 2 periodes de 4 semaines au lieu de 4 periode
de 2 semaines.


3. Pour modeliser l'effet de la visite :

Considerer une relation lineaire.


On pourrait normallement considerer utiliser un estimateur robuste
pour la dependance. Toutefois, puisque la taille d'échantillon est
petite et qu'il y a potentiellement des valeurs extremes, cette option
n'est peut-etre pas ideale. Pour l'essayer, on ferait
PROC MIXED DATA = seizure2 EMPIRICAL;
Note : Cette option ne peut pas etre comparee aux autres 
a l'aide des criteres d'information, puisque c'est une "correction"
aux estimateurs, plutot qu'une modelisation differente a
proprement parler.
*/

PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit;
    MODEL RelCount = visit|TX / DDFM = BW;
    REPEATED visit / SUBJECT = ID TYPE = AR(1); 
RUN;
/*AIC (Smaller is Better) 565.5 
AICC (Smaller is Better) 565.6 
BIC (Smaller is Better) 569.7 
*/


PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit;
    MODEL RelCount = visit|TX / DDFM = BW;
    REPEATED visit / SUBJECT = ID TYPE = ARH(1); 
RUN;
/*
AIC (Smaller is Better) 559.2 
AICC (Smaller is Better) 559.5 
BIC (Smaller is Better) 569.6 
*/

PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit; 
    MODEL RelCount = visit|TX / DDFM = BW;
    RANDOM intercept / SUBJECT = ID; 
RUN;
/*
AIC (Smaller is Better) 568.9 
AICC (Smaller is Better) 568.9 
BIC (Smaller is Better) 573.0 
*/

PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2 EMPIRICAL;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit; 
    MODEL RelCount = visit|TX / DDFM = BW;
    REPEATED visit / SUBJECT = ID TYPE = UN; 
RUN;
/*
AIC (Smaller is Better) 559.6 
AICC (Smaller is Better) 560.7 
BIC (Smaller is Better) 580.4 
*/


/*Du point de vue du AIC et du BIC,
  AR(1) semble le meilleur choix.*/

PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit; 
    MODEL RelCount = visit|TX / 
        DDFM = BW 
        ALPHA = 0.05 
        VCIRY 
        OUTPM = sortie 
        INFLUENCE (ITER = 5 EST);
    REPEATED visit / SUBJECT = ID TYPE = ARH(1); 
    LSMEANS TX*Visit /CL;
    LSMEANS TX /DIFF CL;
    SLICE TX*VISIT / DIFF SLICEBY = visit ALPHA = 0.05;
RUN;
/*Les resultats ne sont pas extremement sensible au choix.
UN est probablement favorise en raison des données extremes,
ce qui peut donner l'impression que les variances residuelles
different selon la visite*/



/*Mais puisque les variances semblent surtout plus grande
chez les placebos, on pourrait plutot mettre que la variance
peut varier selon le traitement : */


PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit; 
    MODEL RelCount = visit|TX / DDFM = BW;
    REPEATED visit / SUBJECT = ID TYPE = AR(1) GROUP = TX; 
        /*L'option GROUP = indique de construire une matrice de variance-
        covariance residuelle differente selon les niveaux de la variable
        dans group.*/
RUN;
/*
AIC (Smaller is Better) 559.9 
AICC (Smaller is Better) 560.0 
BIC (Smaller is Better) 568.2 
*/


/*Cette option obtient le plus petit BIC*/

PROC SORT DATA = seizure2; BY ID Visit; RUN;
PROC MIXED DATA = seizure2;
    CLASS ID TX(REF = first) VISIT;
    ID ID Visit;
    MODEL RelCount = visit|TX / 
        DDFM = KR 
        ALPHA = 0.05 
        VCIRY 
        OUTPM = sortie 
        INFLUENCE (ITER = 5 EST);
    REPEATED visit / SUBJECT = ID TYPE = AR(1) GROUP = TX; 
    LSMEANS TX*Visit /CL;
    LSMEANS TX /DIFF CL;
    SLICE TX*VISIT / DIFF SLICEBY = visit ALPHA = 0.05;
RUN; 
/*Encore une fois, les conclusions sont qualitivativement
similaires*/

/*Puisqu'il n'y a que quelques observations extremes, je ne crois
pas que modeliser des variances differentes soit la meilleure option.*/





