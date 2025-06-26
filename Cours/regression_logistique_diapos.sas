/**************************************************
Ce programme resume le code qui peut etre 
utilise pour ajuster une regression logistique
avec SAS. Ce code devrait etre utilise comme
aide-memoire sur la programmation.

D'autres codes donnant des exemples complets
pour des objectifs specifiques sont 
disponibles.

Exemple 1 - Regression logistique "ordinaire"
Exemple 2 - Regression logistique conditionnelle
**************************************************/

/******* Exemple 1 *******/

ODS GRAPHICS OFF; /*Je ferme les graphiques pour sauver du temps de roulement de programmes*/

/**** Importation des donnees ****/
PROC IMPORT DATAFILE = "C:\Users\denis talbot\Dropbox\Travail\Cours\EPM8006\Automne 2015\Données\fram1.csv"
    OUT = fram1
    REPLACE
    DBMS = CSV;
RUN;


/**** Modele de base ****/
PROC LOGISTIC DATA = fram1 DESCENDING; /*MV*/
    MODEL diabetes = Sex Age BMI cursmoke;
RUN; QUIT;

PROC GENMOD DATA = fram1 DESCENDING; /*MV*/
    MODEL diabetes = Sex Age BMI cursmoke / LINK = logit DIST = binomial;
    ESTIMATE "Sex" Sex 1 / EXP;
RUN; 

PROC GENMOD DATA = fram1 DESCENDING; /*EE*/
    CLASS RANDID;
    MODEL diabetes = Sex Age BMI cursmoke / LINK = logit DIST = binomial;
    ESTIMATE "Sex" Sex 1 / EXP;
    REPEATED SUBJECT = RANDID;
RUN; 

/**** Tests d'hypotheses simultanes et comparaisons ****/
PROC LOGISTIC DATA = fram1 DESCENDING; /*MV*/
    MODEL diabetes = Sex Age BMI cursmoke sex*cursmoke;
    CONTRAST "Effet fum" cursmoke 1, sex*cursmoke 1; /*Test d'hyp. simult.*/
    ESTIMATE "Fumeur vs n-fumeur H" cursmoke 1 sex*cursmoke 1 / EXP CL; /*Comparaison*/
RUN; 

PROC GENMOD DATA = fram1 DESCENDING; /*EE*/
    CLASS RANDID;
    MODEL diabetes = Sex Age BMI cursmoke sex*cursmoke;
    CONTRAST "Effet fum" cursmoke 1, sex*cursmoke 1; /*Test d'hyp. simult.*/
    ESTIMATE "Fumeur vs n-fumeur H" cursmoke 1 sex*cursmoke 1 / EXP; /*Comparaison*/
    REPEATED SUBJECT = RANDID;
RUN; 

/**** Verification des hypotheses ****/
PROC LOGISTIC DATA = fram1 DESCENDING; /*MV*/
    MODEL diabetes = Sex Age BMI cursmoke;
    OUTPUT OUT = sortie_MV P = predit C = Cook
           DFBETAS = dfb0 dfb_sex dfb_age dfb_bmi dfb_cursmoke
           STDRESCHI = resid; 
RUN; QUIT;

PROC GENMOD DATA = fram1 DESCENDING; /*EE*/
    CLASS RANDID;
    MODEL diabetes = Sex Age BMI cursmoke / LINK = logit DIST = binomial;
    ESTIMATE "Sex" Sex 1 / EXP;
    REPEATED SUBJECT = RANDID;
    OUTPUT OUT = sortie_ee P = predit 
           DFBETAS = _all_
           RESCHI = resid;
RUN; 


/* 1. Absence de relation residuelle
Aucune variable continue qui n'est pas modelisee
avec splines, donc non applicable */

/* 2. Independence - ok selon le contexte */

/* 3. Collinearite
vif(fit.ajust); # ok pour les var d'exposition

## 4. Donnees influentes ou extremes
fit.logistic = glm(fracture ~ cons_reg + cons_var + rcs(RIDAGEYR) + rcs(BMXBMI) + rcs(WHD020) + 
                              factor(OSQ130) + factor(OSQ170) + factor(OSQ200) + factor(RIAGENDR) + 
                              factor(RIDRETH1) + factor(MCQ160C) + factor(MCQ160L),
                   family = "binomial",
                   data = ds2);

dfbs = dfbetas(fit.logistic);
summary(dfbs[,2:3]); # Aucune observation influente selon le seuil de +/- 0.2


## 5. Absence de separation
#    Aucun message d'avertissement ou d'IC incroyablement larges

## 6. Surdispersion
# Non applicable






/* 1. Absence de relation residuelle */
PROC SGPLOT DATA = sortie_MV;
    SCATTER X = Age Y = resid;
    PBSPLINE X = Age Y = resid / CLM = "95%CI" CLMTRANSPARENCY = 0.5;
    REFLINE 0;
RUN; /*ok*/

PROC SGPLOT DATA = sortie_EE;
    SCATTER X = Age Y = resid;
    PBSPLINE X = Age Y = resid / CLM = "95%CI" CLMTRANSPARENCY = 0.5;
    REFLINE 0;
RUN; /*ok*/

/* 2. Independance - se verifie selon le contexte */

/* 3. Collinearite */
PROC REG DATA = fram1 PLOTS = NONE;
    MODEL diabetes = Sex Age BMI cursmoke / VIF;
RUN; QUIT; /* ok*/

/* 4. Donnees influentes ou extremes */
PROC SGPLOT DATA = sortie_MV;
    NEEDLE X = RANDID Y = Cook;
RUN; /* Semble ok */

PROC SGPLOT DATA = sortie_MV;
    NEEDLE X = RANDID Y = dfb_cursmoke;
RUN; /* Semble ok */

PROC SGPLOT DATA = sortie_ee;
    NEEDLE X = RANDID Y = stddfbeta_cursmoke;
RUN; /* Semble ok */

/* 5. Absence de separation */
/* Aucun message d'avertissement ou d'IC 
   incroyablement larges */

/* 6. Surdispersion */
/* Impossible comme certaines variables sont continues,
   mais un exemple si on en avait besoin*/

PROC LOGISTIC DATA = fram1 DESCENDING; /*MV*/
    MODEL diabetes = Sex Age BMI cursmoke /
          AGGREGATE = (_all_) SCALE = NONE; 
RUN; QUIT; /* Ok - voir tableau "goodness of fit" */

/* Pas possible pour EE */





/******* Exemple 2 *******/
PROC IMPORT DATAFILE = "C:\Users\denis talbot\Dropbox\Travail\Cours\EPM8006\Donnees\lowbwtm11.csv"
    OUT = lowbw
    REPLACE
    DBMS = CSV;
RUN;

/*Verifier que l'importation s'est bien deroulee*/
PROC CONTENTS DATA = lowbw VARNUM; RUN;

PROC PRINT DATA = lowbw (OBS = 20); RUN;

/*Normallement, on ferait quelques statistiques descriptives*/

/*Il s'agit d'un jeu de donnees provenant d'une etude 
cas-temoin appariee, on devra utiliser une regression logistique conditionnelle
On s'interesse a l'effet de SMOKE sur LOW en ajustant pour les
autres variables. 
Note : puisque apparie sur AGE, le terme
strata(PAIR) ajuste parfaitement pour l'age
*/

/* Ajout d'une variable ID */
DATA lowbw;
    SET lowbw;
    RETAIN ID;
    ID + 1;
RUN;

PROC TRANSREG DATA = lowbw DESIGN;
    MODEL BSPLINE(lwt);
    OUTPUT OUT = sp_lowbw;
    ID ID;
RUN;

DATA lowbw2;
    MERGE lowbw sp_lowbw;
    BY ID;
RUN;


PROC LOGISTIC DATA = lowbw2 DESCENDING;
    CLASS low race pair smoke ht ptd /
       PARAM = REF DESCENDING; 
    /*par defaut, la parametrisation
    utilisee par PROC LOGISTIC compare chaque niveau
    a la moyenne plutot qu'avoir une categorie de ref.*/
    MODEL low = smoke race lwt_1-lwt_3 ht ptd / CL;
    /*L'enonce STRATA permet d'effectuer une
    regression logistique conditionnelle.*/
    STRATA pair;
    /* Exemple test d'hypotheses simultanees :
    H0 : tous les betas confondants = 0
    H1 : Au moins un betas confondants != 0 */
    CONTRAST "confondant" race 1 0, race 0 1,
                          lwt_1 1, lwt_2 1, lwt_3 1,
                          ht 1, ptd 1;
    /* Exemple de comparaison, fumeur avec historique
       d'hypertension vs ni l'un ni l'autre */
    ESTIMATE "smoke + HT = 0" smoke 1 HT 1 / EXP CL;
    OUTPUT OUT = sortie P = predit
        DFBETAS = dfb0 dfb_smoke
        STDRESCHI = resid; 
RUN;
/* RC = 3.7 IC a 95% (1.2 a 12.1) */ 
/* Note : Les test de rapport de vraisemblance, score
et Wald donnent des resultats tres differents; signe
que le n est petit et les inferences peu fiables.
L'option FIRTH n'est pas possible avec regression
logistique conditionnelle...*/
/* On remarque certains IC etrangement larges qui sont
un signe de separation quasi-complete.
J'essaie donc un modele plus simple sans splines */
PROC LOGISTIC DATA = lowbw2 DESCENDING;
    CLASS low race pair smoke ht ptd /
       PARAM = REF DESCENDING; 
    MODEL low = smoke race lwt ht ptd / CL;
    STRATA pair;
RUN;
/* RC = 3.6 IC a 95 %  (1.2 a 10.9) */ 
/* Les resultats pour smoke sont similaires, je prefere
le modele avec splines pour faire un meilleur ajustement 
Aussi un choix plus conservateur, car IC plus large */


/**** Verification des hypotheses ****/

/* 1. Absence de relation residuelle */
* Seule variable continue modelisee avec splines,
donc non applicable. 
L'exemple ci-dessous est a titre illustratif seulement;
PROC SGPLOT DATA = sortie;
    SCATTER X = lwt Y = resid;
    LOESS X = lwt Y = resid / CLM = "95%CI" CLMTRANSPARENCY = 0.5;
    REFLINE 0;
RUN; /*ok*/


/* 2. Independance - se verifie selon le contexte, ok */

/* 3. Collinearite */
*Il faut creer les variables indicatrices
pour PROC REG;
DATA lowbw_reg;
    SET lowbw2;
    IF race = 1 THEN DO;
        race1 = 1; race2 = 0;
    END;
    IF race = 2 THEN DO;
        race1 = 0; race2 = 1;
    END;
    IF race = 3 THEN DO;
        race1 = 0; race2 = 0;
    END;
RUN;

PROC REG DATA = lowbw_reg PLOTS = NONE;
    MODEL low = smoke race1 race2 lwt_1-lwt_3 ht ptd / VIF;
RUN; QUIT; /* vif smoke < 10 = ok*/

/* 4. Donnees influentes ou extremes */
PROC SGPLOT DATA = sortie;
    NEEDLE X = ID Y = dfb_smoke;
RUN; /* Certaines observations influentes */

PROC PRINT DATA = sortie;
    WHERE abs(dfb_smoke) > 0.2;
RUN;
/*
On pourrait faire des analyses de sensibilite, 
mais si on retire une observation d'une paire,
la paire au complet devient inutilisable
Avec un petit echantillon, 
peu surprenant que les resultats soient
tres influences par certaines observations
*/

/* 5. Absence de separation */
/* On avait remarque des IC problematiques,
   mais l'analyse de sensibilite suggere que
   notre modele est ok*/

/* 6. Surdispersion */
* Non applicable comme on a une variable continue;
* Si on en avait besoin :
les tests ne peuvent pas etre utilises avec
la regression  logistique conditionnelle.
Meilleure option serait de verifier avec une
regression logistique "ordinaire" en ajustant
pour les facteurs d'appariement (ici l'age);

