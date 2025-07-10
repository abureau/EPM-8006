libname modeli "/workspaces/workspace/Données EPM-8006";

data pol; set modeli.chp04;
if prem = 2 then prem01 = 0; else prem01 = 1;
/* La variable PARIT est ramenée à trois catégories: 0, 1, 2&+. 
   Deux variables indicatrices sont utilisées: PAR0, PAR1 */
if parit=0 then par0=1; else par0=0;
if parit=1 then par1=1; else par1=0;

/* On permet que la pente après 32 semaine soit distincte de la pente
   avant 32 semaines en définissant une variable additionnelle GEST32
   qui est égale à GEST – 32 si GEST > 32 et est égale à 0 sinon. */
if gest>32 then gest32 = gest - 32; else gest32 = 0;
run;


/* Estimation par maximum de vraisemblance: problème de convergence */
proc genmod data=pol descending;
   model prem01=age par0 par1 gest gest32 gemel transf / dist=bin link=log;
run;



/* Régression de Poisson */

proc genmod data=pol descending;
   class idn;
   model prem01=age par0 par1 gest gest32 gemel transf / dist=Poisson link=log;
   /* L'usage de l'énoncé repeated est un truc pour obtenir les estimations robustes
      des erreurs-types. En réalité, il y a une seule observation par sujet. */
   repeated subject=idn / type=ind printmle;
/* Calcul du risque relatif en prenant l'exponentiel des coefficients */
   estimate "age" age 1;
   estimate "par0" par0 1;
   estimate "par1" par1 1;
   estimate "gest" gest 1;
   estimate "gest32" gest32 1;
   estimate "transf" transf 1;
run;

/* Régression non-linéaire avec erreurs normales */

proc genmod data=pol descending;
   class idn;
   model prem01=age par0 par1 gest gest32 gemel transf / dist=normal link=log;
   /* L'usage de l'énoncé repeated est un truc pour obtenir les estimations robustes
      des erreurs-types. En réalité, il y a une seule obsevation par sujet. */
   repeated subject=idn / type=ind printmle;
/* Calcul du risque relatif en prenant l'exponentiel des coefficients */
   estimate "age" age 1;
   estimate "par0" par0 1;
   estimate "par1" par1 1;
   estimate "gest" gest 1;
   estimate "gest32" gest32 1;
   estimate "transf" transf 1;
run;

/* On obtient les mêmes estimations avec proc nlin */
proc nlin data=pol;
   model prem01 = exp(beta0 + beta1*age + beta2*par0 + beta3*par1 + beta4*gest + beta5*gest32 + beta6*gemel + beta7*transf);
   parms beta0 = 0, beta1 = 0, beta2 = 0, beta3 = 0, beta4 = 0, beta5 = 0, beta6 = 0, beta7 = 0;
run;

/* Analyse sous le modèle logistique (pour fins de comparaison) */
proc logistic data=pol descending;
   model prem01=age par0 par1 gest gest32 gemel transf;
run;
