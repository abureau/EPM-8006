/* Lecture du jeu de données sur l'amenorrhée de FLW*/

data amenorrhea;
  infile "amenorrhea.dat";
  input ID Dose temps Amenorrhea;
run;

/* Analyse des données disponibles  */

proc genmod data=amenorrhea desc;
class id;
model amenorrhea = dose temps temps*temps dose*temps dose*temps*temps / dist=bin;
repeated subject=id / logor=fullclust modelse;
output out=predad p=pameno;
run;


/* Imputation multiple

Transformation du format long en format large par transposition des mesures répétées */
proc transpose data=amenorrhea out=amenlarge prefix=temps;
by ID;
id temps;
var Amenorrhea;
run;

/* Ajout de la variable dose, fixe pour chaque sujet 
   Il faut commencer par éliminer les duplicats.
*/
proc sort data=amenorrhea out=amendose nodupkey;
by ID;
run;

data amenlarge;
merge amenlarge amendose;
by ID;
drop temps amenorrhea;
run;

/* Vérification que la dose et la mesure au temps 1 prédisent la mesure au temps 2 */
proc logistic data=amenlarge desc;
  model temps2 = temps1 dose;
run;

/* Imputation multiple des réponses des sujets perdus au suivi en exploitant la monotonicité */
proc mi data=amenlarge out=amenimpute seed=11;
class temps1 temps2 temps3 temps4;
var dose temps1 temps2 temps3 temps4;
monotone logistic (temps2=dose temps1 dose*temps1) ;
monotone logistic (temps3=dose temps1 dose*temps1 temps2 dose*temps2); 
monotone logistic (temps4=dose temps1 dose*temps1 temps2 dose*temps2 temps3 dose*temps3);
run;

/* Reconversion en format long pour l'analyse */
data amenanalyse;
set amenimpute;
y=temps1; temps=0; output;
y=temps2; temps=1; output;
y=temps3; temps=2; output;
y=temps4; temps=3; output;
drop temps1 temps2 temps3 temps4;
run;


/* Analyse avec le modèle proposé par FLW à la section 12.5 */
proc genmod data=amenanalyse desc;
by _imputation_;
class id;
model y = dose temps temps*temps dose*temps dose*temps*temps / dist=bin;
repeated subject=id / logor=fullclust modelse corrw;
ods output GEEEmpPEst=parms;
run;

proc sort data=parms;
by parm;

/* Combinaison des estimations des imputations. Remarquez qu'au lieu de nommer chaque effet, 
   on boucle sur tous les paramètres avec l'énoncé by*/
proc mianalyze data=parms;
  modeleffects estimate;
  stderr stderr; 
  by parm;
ods output parameterEstimates=coefimpute;
  run;

/* Méthode de pondération des observations */

data contracep;

     infile 'contracep.dat';

     input id dose temps y prevy r;
     
proc sort data=contracep;

     by id temps;

run;

/* Analyse des données complètes pour vérifier qu'on obtient plus ou moins la même chose que précédemment */
proc genmod data=contracep desc;
class id;
model y = dose dose temps temps*temps dose*temps dose*temps*temps / dist=bin;
repeated subject=id / logor=fullclust modelse corrw;
run;



title1 Logistic Regression Model for Probability of Remaining in the Study; 

title2 Clinical Trial of Contracepting Women;

/* Modèle de la probabilité d'observer la réponse y */ 
proc genmod descending data=contracep;

     class temps (param=ref ref="1");

     model r = temps dose prevy dose*prevy / dist=bin link=logit;

     where temps ne 0;

     output out=predict p=probs;

run;

/* Si on voulait calculer un SIPCW, la procédure suivante nous donnerait le numérateur. Nous ne calculerons pas 
de SIPCW ici.
proc genmod descending data = contracep;

     class temps (param=ref ref="1");

     model r = temps / dist=bin link=logit;

     where temps ne 0;

     output out=numer p=probs;

run; */
 

proc sort data=predict;

     by id temps;
run;
 
/* Calcul des poids */
data wgt (keep=id temps cumprobs probs);

     set predict;

     by id temps;

     retain cumprobs;

     if first.id then cumprobs=probs;

     else cumprobs=cumprobs*probs;

 

data combine;

     merge contracep wgt;

     by id temps;

     if (temps=0) then ipw=1;

     else ipw=1/cumprobs;

run; 

proc sort data=combine;
by temps;
run;

proc means data=combine;
var y;
by temps;
	OUTPUT OUT = nt N = nt;
RUN;

proc means data=combine;
var ipw;
by temps;
	OUTPUT OUT = ns SUM = sipw;
RUN;

data combine2;
merge combine ns nt;
nipw = ipw/(sipw/nt);
by temps;
run;

title1 IPW-GEE Estimation of Marginal Logistic Regression Model for Odds of Amenorrhea;

title2 Clinical Trial of Contracepting Women;

 
/* Estimation du modèle en pondérant les observations */

proc genmod descending data=combine;

     weight ipw;

     class id;

     model y = dose temps temps*temps dose*temps dose*temps*temps / dist=bin link=logit;
/* La seule structure de corrélation avec laquelle la pondération donnera des résultats valides est indépendance */
     repeated subject=id / type=ind;
     output out=predipw p=pameno;
run;

/* L'utilisation de poids standardisés ne change pas les estimations robuste de la variance 
et affecte peu les coefficients. Les coefficients s'éloignent un peu des estimations par imputation multiple */
proc genmod descending data=combine2;

     weight nipw;

     class id;

     model y = dose temps temps*temps dose*temps dose*temps*temps / dist=bin link=logit;
/* La seule structure de corrélation avec laquelle la pondération donnera des résultats valides est indépendance */
     repeated subject=id / type=ind;
     output out=predipw p=pameno;
run;


/* Tableau de probabilités prédites en fonction du temps et de la dose */
data predtab;
  set predipw;
  where id = 423 or id = 425;
  keep dose temps pameno;
run;

/* La pondération ipw ou nipw ne change pas les résultats si on a un modèle saturé incluant le temps
   (on fait une analyse séparée à chaque temps de mesure)*/
proc genmod descending data=combine2;

     weight nipw;

     class id temps;

     model y = dose|temps / dist=bin link=logit;
/* La seule structure de corrélation avec laquelle la pondération donnera des résultats valides est indépendance */
     repeated subject=id / type=ind;
     output out=predipw p=pameno;
run;
