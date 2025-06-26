
/* Recodage de variables */
data exam; set sasuser.chp09;
/* Définition de la variable réponse: y = 1 si un décès est survenu, 2 sinon. */
if deces=1 then y=1; else y=2;
/* Définition d'une variable coma: coma = 1 si inconscient */
if cons=0 then coma=0; else coma=1;

/* Génération d'une variable aléatoire uniforme entre 0 et 1 pour sélectionner 
   aléatoirement les observations du jeu de données d'élaboration et celles 
   du jeu de données de validation. On passe à la fonction ranuni un nombre 
   entier arbitraire comme germe de la séquence de nombres pseudo-aléatoires. */
rn = ranuni(138);
run;

/* Séparation de l'échantillon en échantillon d'élaboration (ech1) et de validation (ech2) */
data ech1 ech2;
set exam;
/* Les observations dont le nombre aléatoire est < 0.8 vont dans ech1 */
if rn < 0.8 then output ech1;
/* Les autres vont dans ech2. */
else output ech2;
run;

/* Activation de l'option graphique (inutile si votre installation de SAS envoie les sorties
   à une fenêtre graphique par défaut.)*/
  ods graphics on;
  ods html on;

/* Estimation de 3 différents modèles prédictifs.

  Je présentes deux approches, A et B, qui font presqu'exactement la même chose.

  A) Approche en deux temps: 1-On sauvegarde les modèles estimés avec l'option outmodel=. 
  et 2- on charge un modèle existant avec l'option inmodel dans un autre appel à la 
  procédure LOGISTIC. */
proc logistic data=ech1 outmodel=mod1;
 model y=coma;
run;

proc logistic data=ech1 outmodel=mod2;
 model y=coma age;
run;

/* Avec le modèle complet, on en profite pour créer des graphiques
   des courbes ROC des 3 modèles pour l'échantillon d'élaboration 
   avec les énoncés roc. Remarquez qu'un énoncé roc pour le modèle 3
   spécifié dans l'énoncé model n'est pas requis; la courbe ROC pour 
   ce modèle est affichée par défaut, et est étiquettée "Modèle". */
proc logistic data=ech1 outmodel=mod3;
 model y=coma age soin;
 roc 'modèle 1' coma;
 roc 'modèle 2' coma age;
run;

/* Calcul des scores T de chaque modèle sur l'échantillon de validation.
   Remarquez qu'on charge un modèle existant avec l'option inmodel, au lieu
   d'en estimer sur les données. Les probabilités prédites (scores T) sont
   écrites dans le tableau de données spécifié par out=.
   L'option outroc= crée un tableau de données SAS avec les coordonnées
   de la courbe ROC du modèle. Elle devrait aussi faire afficher la courbe ROC,
   mais cela ne marche pas dans mon installation de SAS. Dans ce cas, il faut 
   plutôt se servir de l'énoncé roc. Un exemple pour superposer 3 courbes ROC
   est donné après l'approche B. */
proc logistic inmodel=mod1; 
      score data=ech2 fitstat out=pred1 outroc = roc1; 
   run;

proc logistic inmodel=mod2; 
      score data=ech2 fitstat out=pred2 outroc = roc2; 
   run;

proc logistic inmodel=mod3; 
      score data=ech2 fitstat out=pred3 outroc = roc3; 
   run;

/*  B) Approche simultanée: on estime le modèle et on calcule le 
     score sur l'échantillon de validation dans le même appel à
     la procédure LOGISTIC. L'option rocoptions(id=cutpoint) 
     permet d'afficher les points de coupure du score T sur 
     la courbe ROC pour l'échantillon de validation produite
     par l'option outroc de l'énoncé score.*/
proc logistic data=ech1 rocoptions(id=cutpoint);
 model y=coma;
 score data=ech2 fitstat out=pred1 outroc = roc1; 
run;

proc logistic data=ech1 rocoptions(id=cutpoint);
 model y=coma age;
 score data=ech2 fitstat out=pred2 outroc = roc2; 
run;

/* Avec le modèle complet, on en profite pour créer des graphiques
   des courbes ROC superposées des 3 modèles pour l'échantillon d'élaboration 
   avec les énoncés roc. Remarquez qu'un énoncé roc pour le modèle 3
   spécifié dans l'énoncé model n'est pas requis; la courbe ROC pour 
   ce modèle est affichée par défaut, et est étiquettée "Modèle". */
proc logistic data=ech1 rocoptions(id=cutpoint);
 model y=coma age soin;
 score data=ech2 fitstat out=pred3 outroc = roc3; 
 roc 'modèle 1' coma;
 roc 'modèle 2' coma age;
run;


/* Traçage des courbes ROC des 3 modèles dans les échantillons de validation 
   sur le même graphique */

/* Les étapes préliminaires ci-dessous réunissent les prédictions des 3 modèles 
   dans un seul tableau de données SAS.

   On commence par renommer la probabilité prédite, ici appelée p_2, pour lui 
   donner un nom spécifique à chaque modèle. */
data pred3;
  set pred3;
  rename p_1 = p_mod3;

data pred2;
  set pred2;
  rename p_1 = p_mod2;

data pred1;
  set pred1;
  rename p_1 = p_mod1;
run;

/* Ensuite, on combine les probabilités prédites des 3 modèles en un seul
   tableau de données. */
data predtous;
  merge pred1 pred2 pred3;
run;

/* Ici, on se sert de la procédure logistique seulement pour produire des courbes ROC.
   On inclut un énoncé model seulement parce qu'il est exigé avec un énoncé roc,
   mais on s'assure qu'il ne fait rien en spécifiant l'option nofit. */
proc logistic data=predtous; 
 model y= p_mod1 p_mod2 p_mod3 / nofit;
 roc 'modèle 1' p_mod1;
 roc 'modèle 2' p_mod2;
 roc 'modèle 3' p_mod3;
run;
ods graphics off;
