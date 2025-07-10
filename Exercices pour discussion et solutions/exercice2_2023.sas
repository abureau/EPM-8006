libname modeli "/workspaces/workspace/Données EPM-8006";

/* ## Recodage de la variable réponse et des variables explicatives */
data exe; set modeli.exe11_01;

if satisf='tres'  then y=4;
if satisf='assez' then y=3;
if satisf='peu'   then y=2;
if satisf='pas'   then y=1;

if age   ='jeune' then ag=1; else ag=0;
if moment='pm'    then mom=1; else mom=0;
run;


/* Analyse sous l'hypothèse des cotes proportionnelles */

proc logistic des;
 model y=mom ag mom*ag;
 freq f;
run;

/* On rejette de peu l'hypothèse nulle des cotes proportionnelles au niveau de signification 0.05. 
On a le choix de poursuivre avec ce modèle, ou avec le modèle de régression multinomiale non-ordonnée. */


/* 1- Poursuivre avec le modèle multinomial non-ordonné (Analyse glogit) */
proc logistic;
 model y=mom ag mom*ag / link=glogit;
 freq f;
run;

/* Il n'y a pas d'évidence de modification de l'effet du moment de la journée par l'âge (Analyse des effets Type 3: mom*ag p = 0.7054).
On estime donc les RCs conditionnels à l'âge pour les divers niveaux de satisfaction d'une consultation en PM vs. AM dans un modèle 2 sans terme d'interaction. */

proc logistic;
 model y=mom ag / link=glogit;
 freq f;
run;

/* On observe donc que les patients sont plus portés à rapporter des niveaux de satisfaction bas si leur visite est en PM plutôt qu'en AM.

On peut aussi estimer des RCs bruts sans ajuster pour l'âge puisque ce n'était pas demandé dans la question.*/
proc logistic;
 model y=mom/ link=glogit;
 freq f;
run;

/* Les résultats bruts suggèrent un rapport de cote d'insatisfaction plus grand entre une visite en PM vs. AM
que lorsqu'on ajuste pour l'âge. Il peut s'agir simplement d'une différence de définition due à la non-collapsibilité du RC.

2- Poursuivre avec le modèle de régression ordinale avec cotes proportionnelles

On rapporte le RC pour des niveaux de satisfaction plus élevés d'une consultation en PM vs. AM, 
conditionnel à l'âge.  */
proc logistic des;
 model y=mom ag;
 freq f;
run;
/* 

On remarque que l'hypothèse de cotes proportionnelles est plus fortement rejetée. On observe néanmoins 
que les patients sont moins portés à rapporter des niveaux de satisfaction plus élevés si leur visite est en PM plutôt qu'en AM. 
(En d'autres termes, les patients sont plus portés à rapporter des niveaux de satisfaction plus bas si leur visite est en PM plutôt qu'en AM.)


On peut aussi estimer un RC brut sans ajuster pour l'âge puisque ce n'était pas demandé dans la question.*/

proc logistic des;
 model y=mom;
 freq f;
run;

/* Le RC brut est plus grand entre une visite en PM vs. AM que lorsqu'on ajuste pour l'âge. 
Il peut s'agir simplement d'une différence de définition due à la non-collapsibilité du RC. 
Les conclusions restent semblables à celles en ajustant pour l'âge. 
L'hypothèse de cotes proportionnelles n'est pas rejetée.

Une autre alternative serait de procéder à une analyse alogit (catégories adjacentes)*/
proc logistic des;
 model y=mom ag mom*ag / link=alogit;
 freq f;
run;

proc logistic des;
 model y=mom ag / link=alogit;
 freq f;
run;
