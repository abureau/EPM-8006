
/* Recodage de variables */
data exam; set sasuser.chp09;
/* D�finition de la variable r�ponse: y = 1 si un d�c�s est survenu, 2 sinon. */
if deces=1 then y=1; else y=2;
/* D�finition d'une variable coma: coma = 1 si inconscient */
if cons=0 then coma=0; else coma=1;

/* G�n�ration d'une variable al�atoire uniforme entre 0 et 1 pour s�lectionner 
   al�atoirement les observations du jeu de donn�es d'�laboration et celles 
   du jeu de donn�es de validation. On passe � la fonction ranuni un nombre 
   entier arbitraire comme germe de la s�quence de nombres pseudo-al�atoires. */
rn = ranuni(138);
run;

/* S�paration de l'�chantillon en �chantillon d'�laboration (ech1) et de validation (ech2) */
data ech1 ech2;
set exam;
/* Les observations dont le nombre al�atoire est < 0.8 vont dans ech1 */
if rn < 0.8 then output ech1;
/* Les autres vont dans ech2. */
else output ech2;
run;

/* Activation de l'option graphique (inutile si votre installation de SAS envoie les sorties
   � une fen�tre graphique par d�faut.)*/
  ods graphics on;
  ods html on;

/* Estimation de 3 diff�rents mod�les pr�dictifs.

  Je pr�sentes deux approches, A et B, qui font presqu'exactement la m�me chose.

  A) Approche en deux temps: 1-On sauvegarde les mod�les estim�s avec l'option outmodel=. 
  et 2- on charge un mod�le existant avec l'option inmodel dans un autre appel � la 
  proc�dure LOGISTIC. */
proc logistic data=ech1 outmodel=mod1;
 model y=coma;
run;

proc logistic data=ech1 outmodel=mod2;
 model y=coma age;
run;

/* Avec le mod�le complet, on en profite pour cr�er des graphiques
   des courbes ROC des 3 mod�les pour l'�chantillon d'�laboration 
   avec les �nonc�s roc. Remarquez qu'un �nonc� roc pour le mod�le 3
   sp�cifi� dans l'�nonc� model n'est pas requis; la courbe ROC pour 
   ce mod�le est affich�e par d�faut, et est �tiquett�e "Mod�le". */
proc logistic data=ech1 outmodel=mod3;
 model y=coma age soin;
 roc 'mod�le 1' coma;
 roc 'mod�le 2' coma age;
run;

/* Calcul des scores T de chaque mod�le sur l'�chantillon de validation.
   Remarquez qu'on charge un mod�le existant avec l'option inmodel, au lieu
   d'en estimer sur les donn�es. Les probabilit�s pr�dites (scores T) sont
   �crites dans le tableau de donn�es sp�cifi� par out=.
   L'option outroc= cr�e un tableau de donn�es SAS avec les coordonn�es
   de la courbe ROC du mod�le. Elle devrait aussi faire afficher la courbe ROC,
   mais cela ne marche pas dans mon installation de SAS. Dans ce cas, il faut 
   plut�t se servir de l'�nonc� roc. Un exemple pour superposer 3 courbes ROC
   est donn� apr�s l'approche B. */
proc logistic inmodel=mod1; 
      score data=ech2 fitstat out=pred1 outroc = roc1; 
   run;

proc logistic inmodel=mod2; 
      score data=ech2 fitstat out=pred2 outroc = roc2; 
   run;

proc logistic inmodel=mod3; 
      score data=ech2 fitstat out=pred3 outroc = roc3; 
   run;

/*  B) Approche simultan�e: on estime le mod�le et on calcule le 
     score sur l'�chantillon de validation dans le m�me appel �
     la proc�dure LOGISTIC. L'option rocoptions(id=cutpoint) 
     permet d'afficher les points de coupure du score T sur 
     la courbe ROC pour l'�chantillon de validation produite
     par l'option outroc de l'�nonc� score.*/
proc logistic data=ech1 rocoptions(id=cutpoint);
 model y=coma;
 score data=ech2 fitstat out=pred1 outroc = roc1; 
run;

proc logistic data=ech1 rocoptions(id=cutpoint);
 model y=coma age;
 score data=ech2 fitstat out=pred2 outroc = roc2; 
run;

/* Avec le mod�le complet, on en profite pour cr�er des graphiques
   des courbes ROC superpos�es des 3 mod�les pour l'�chantillon d'�laboration 
   avec les �nonc�s roc. Remarquez qu'un �nonc� roc pour le mod�le 3
   sp�cifi� dans l'�nonc� model n'est pas requis; la courbe ROC pour 
   ce mod�le est affich�e par d�faut, et est �tiquett�e "Mod�le". */
proc logistic data=ech1 rocoptions(id=cutpoint);
 model y=coma age soin;
 score data=ech2 fitstat out=pred3 outroc = roc3; 
 roc 'mod�le 1' coma;
 roc 'mod�le 2' coma age;
run;


/* Tra�age des courbes ROC des 3 mod�les dans les �chantillons de validation 
   sur le m�me graphique */

/* Les �tapes pr�liminaires ci-dessous r�unissent les pr�dictions des 3 mod�les 
   dans un seul tableau de donn�es SAS.

   On commence par renommer la probabilit� pr�dite, ici appel�e p_2, pour lui 
   donner un nom sp�cifique � chaque mod�le. */
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

/* Ensuite, on combine les probabilit�s pr�dites des 3 mod�les en un seul
   tableau de donn�es. */
data predtous;
  merge pred1 pred2 pred3;
run;

/* Ici, on se sert de la proc�dure logistique seulement pour produire des courbes ROC.
   On inclut un �nonc� model seulement parce qu'il est exig� avec un �nonc� roc,
   mais on s'assure qu'il ne fait rien en sp�cifiant l'option nofit. */
proc logistic data=predtous; 
 model y= p_mod1 p_mod2 p_mod3 / nofit;
 roc 'mod�le 1' p_mod1;
 roc 'mod�le 2' p_mod2;
 roc 'mod�le 3' p_mod3;
run;
ods graphics off;
