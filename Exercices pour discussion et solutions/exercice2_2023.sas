libname modeli " C:\Users\etudiant\Documents\EPM-8006\donnees";

/* ## Recodage de la variable r�ponse et des variables explicatives */
data exe; set modeli.exe11_01;

if satisf='tres'  then y=4;
if satisf='assez' then y=3;
if satisf='peu'   then y=2;
if satisf='pas'   then y=1;

if age   ='jeune' then ag=1; else ag=0;
if moment='pm'    then mom=1; else mom=0;
run;


/* Analyse sous l'hypoth�se des cotes proportionnelles */

proc logistic des;
 model y=mom ag mom*ag;
 freq f;
run;

/* On rejette de peu l'hypoth�se nulle des cotes proportionnelles au niveau de signification 0.05. 
On a le choix de poursuivre avec ce mod�le, ou avec le mod�le de r�gression multinomiale non-ordonn�e. */


/* 1- Poursuivre avec le mod�le multinomial non-ordonn� (Analyse glogit) */
proc logistic;
 model y=mom ag mom*ag / link=glogit;
 freq f;
run;

/* Il n'y a pas d'�vidence de modification de l'effet du moment de la journ�e par l'�ge (Analyse des effets Type 3: mom*ag p = 0.7054).
On estime donc les RCs conditionnels � l'�ge pour les divers niveaux de satisfaction d'une consultation en PM vs. AM dans un mod�le 2 sans terme d'interaction. */

proc logistic;
 model y=mom ag / link=glogit;
 freq f;
run;

/* On observe donc que les patients sont plus port�s � rapporter des niveaux de satisfaction bas si leur visite est en PM plut�t qu'en AM.

On peut aussi estimer des RCs bruts sans ajuster pour l'�ge puisque ce n'�tait pas demand� dans la question.*/
proc logistic;
 model y=mom/ link=glogit;
 freq f;
run;

/* Les r�sultats bruts sugg�rent un rapport de cote d'insatisfaction plus grand entre une visite en PM vs. AM
que lorsqu'on ajuste pour l'�ge. Il peut s'agir simplement d'une diff�rence de d�finition due � la non-collapsibilit� du RC.

2- Poursuivre avec le mod�le de r�gression ordinale avec cotes proportionnelles

On rapporte le RC pour des niveaux de satisfaction plus �lev�s d'une consultation en PM vs. AM, 
conditionnel � l'�ge.  */
proc logistic des;
 model y=mom ag;
 freq f;
run;
/* 

On remarque que l'hypoth�se de cotes proportionnelles est plus fortement rejet�e. On observe n�anmoins 
que les patients sont moins port�s � rapporter des niveaux de satisfaction plus �lev�s si leur visite est en PM plut�t qu'en AM. 
(En d'autres termes, les patients sont plus port�s � rapporter des niveaux de satisfaction plus bas si leur visite est en PM plut�t qu'en AM.)


On peut aussi estimer un RC brut sans ajuster pour l'�ge puisque ce n'�tait pas demand� dans la question.*/

proc logistic des;
 model y=mom;
 freq f;
run;

/* Le RC brut est plus grand entre une visite en PM vs. AM que lorsqu'on ajuste pour l'�ge. 
Il peut s'agir simplement d'une diff�rence de d�finition due � la non-collapsibilit� du RC. 
Les conclusions restent semblables � celles en ajustant pour l'�ge. 
L'hypoth�se de cotes proportionnelles n'est pas rejet�e.

Une autre alternative serait de proc�der � une analyse alogit (cat�gories adjacentes)*/
proc logistic des;
 model y=mom ag mom*ag / link=alogit;
 freq f;
run;

proc logistic des;
 model y=mom ag / link=alogit;
 freq f;
run;
