/* Examen des résidus du modèle de la croissance de capacité
   pulmonaire de la Six Cities Study of Air Pollution and Health */
libname donnees "C:\Users\etudiant\Documents\EPM-8006\donnees";

data fev;
     infile 'fev1.dat';
     input id ht age baseht baseage logfev1; 

loght=log(ht);
logbht=log(baseht);

run;

/* Linear Mixed Effects Model (Random Intercept and Slope for Age) */

 

title1 Mixed Effects Model for log(FEV1) with Random Intercept and Slope for Age;
title2 Six Cities Study;

/* On spécifie l'option covtest pour demander les erreurs-types 
   pour les paramètres de covariance. SAS effectue en même temps
   les tests de Wald, mais il ne faut pas s'y fier. */
proc mixed data=fev method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel;  
     class id;
     model logfev1 = age loght baseage logbht / s chisq residual vciry outpm=fevp;
     random intercept age / subject=id type=un g gcorr v=35 vcorr=35; 
run;

/* Identification des résidus extrêmes */
data fevaber;
  set fevp;
  if scaledresid < -4;
run;

/* On enlève le résidu le plus extrême et on refait l'analyse. */
data fev2;
  set fev;
*if (id ne 197 and id ne 30 and id ne 118 and id ne 120 and id ne 131 and id ne 246);
if (id ne 197 );
run;

/* Création de variables pour changement de pente à 12 et à 15 ans */
data fev2;
  set fev2;
  age12 = max(age-12,0);
  age15 = max(age-15,0);
run;

/* On spécifie l'option covtest pour demander les erreurs-types 
   pour les paramètres de covariance. SAS effectue en même temps
   les tests de Wald, mais il ne faut pas s'y fier. */
proc mixed data=fev2 method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel;  
     class id;
     model logfev1 = age loght baseage logbht / s chisq residual vciry outpm=fevp;
     random intercept age / subject=id type=un g gcorr v=35 vcorr=35; 
run;

/* Comme SAS retourne la réponse transformée au lieu de la valeur moyenne prédite
   transformée, on calcule la valeur moyenne prédite
   transformée en soustrayant les résidus transformés
   de la réponse transformée. */
data fevp;
  set fevp;
  predt = scaleddep - scaledresid;
run;
/* Lissage avec proc loess */

/* Lissage des résidus bruts en fonction de la moyenne prédite. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model resid = pred / clm select=df1(4);
run;

/* Lissage des résidus transformés en fonction de la moyenne prédite transformée. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model scaledresid = predt / clm select=df1(4);
run;

/* Lissage des résidus bruts en fonction de l'âge. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model resid = age / clm select=df1(4);
run;

/* Lissage des résidus transformés en fonction de l'âge. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model scaledresid = age / clm select=df1(4);
run;

/* Lissage des résidus bruts en fonction de la log taille. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model resid = loght / clm select=df1(4);
run;

/* Lissage des résidus transformés en fonction de la log taille */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model scaledresid = loght / clm select=df1(4);
run;

/* Modélisation de l'âge en 3 segments */
proc mixed data=fev2 method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel;  
     class id;
     model logfev1 = age age12 age15 loght baseage logbht / s chisq residual vciry outpm=fevp;
     random intercept age age12 age15 / subject=id type=un g gcorr v=35 vcorr=35; 
run;
