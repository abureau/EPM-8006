
/* MIT Growth and Development Study
 

 

Linear Mixed Effects Model (Random Intercept and Slopes) */

 

 

data fat;
     infile 'fat.dat';
     input id age agemen time pbf;

/* Création d'une variable pour le changement de pente après temps 0 */
time_0=max(time,0);
run;

title1 Mixed Effects Model for Percent Body Fat with Random Intercept and Slopes before and after Menarche;
title2 MIT Growth and Development Study;

ods graphics on;

/* On spécifie l'option covtest pour demander les erreurs-types 
   pour les paramètres de covariance. SAS effectue en même temps
   les tests de Wald, mais il ne faut pas s'y fier. 

   l'option plots=residualpanel produit des graphiques des résidus bruts et "studentisés",
   alors que plots=vcirypanel produit des graphiques des résidus transformés ("résidus mis 
   à l'échelle" dans la terminologie de SAS.) */
proc mixed method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel; 
     class id;
     /* L'option residual demande de produire les residus bruts et "studentisés".
	    L'option vciry demande de produre les residus transformés.
	    Ces résidus, les valeurs transformées de la réponse et les valeurs prédites 
	    de la moyenne sont écrites dans le fichier spécifié avec l'option outpm= .*/
     model pbf = time time_0 / s chisq residual vciry outpm=fatp;
     random intercept time time_0 / subject=id type=un g gcorr v vcorr; 
run;

/* Comme SAS retourne la réponse transformée au lieu de la valeur moyenne prédite
   transformée, on calcule la valeur moyenne prédite
   transformée en soustrayant les résidus transformés
   de la réponse transformée. */
data fatp;
  set fatp;
  predt = scaleddep - scaledresid;
run;

/* Lissage avec proc loess */

/* Lissage des résidus bruts en fonction de la moyenne prédite. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model resid = pred / clm select=df1(4);
run;

/* Lissage des résidus transformés en fonction de la moyenne prédite transformée. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model scaledresid = predt / clm select=df1(4);
run;

/* Lissage des résidus bruts en fonction du temps. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model resid = time / clm select=df1(4);
run;

/* Lissage des résidus transformés en fonction du temps. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model scaledresid = time / clm select=df1(4);
run;

/* Lissage avec prog gam */

/* Lissage des résidus bruts en fonction de la moyenne prédite. */
proc gam data=fatp plots=all;
   model resid = loess(pred,df=4);
   output out=fatb p uclm lclm;
run;

/* Lissage des résidus transformés en fonction de la moyenne prédite transformée. */
proc gam data=fatp;
   model scaledresid = loess(predt,df=4);
   output out=fatt p uclm lclm;
run;


/* Lissage des résidus bruts en fonction du temps. */
proc gam data=fatp;
   model resid = loess(time,df=4);
   output out=fatbt p uclm lclm;
run;

/* Lissage des résidus transformés en fonction du temps. */
proc gam data=fatp;
   model scaledresid = loess(time,df=4);
   output out=fattt p uclm lclm;
run;

/* Graphiques */

/* tri en ordre croissant d'âge pour faire le graphique */
 proc sort data=fatt out=plot_fatt; by predt; run;

proc gplot data=plot_fatt;
/* graphique des résidus transformés vs. le temps */
  plot scaledresid*predt P_scaledresid*predt=2 /overlay  frame;
run;
 
/* tri en ordre croissant d'âge pour faire le graphique */
 proc sort data=fatb out=plot_fatb; by pred; run;

proc gplot data=plot_fatb;
/* graphique des résidus bruts vs. le temps */
  plot resid*pred P_resid*pred=2 /overlay  frame;
run;
 

/* tri en ordre croissant d'âge pour faire le graphique */
 proc sort data=fattt out=plot_fattt; by time; run;

proc gplot data=plot_fattt;
/* graphique des résidus transformés vs. le temps */
  plot scaledresid*time P_scaledresid*time=2 /overlay  frame;
run;
 
/* tri en ordre croissant d'âge pour faire le graphique */
 proc sort data=fatbt out=plot_fatbt; by time; run;

proc gplot data=plot_fatbt;
/* graphique des résidus bruts vs. le temps */
  plot resid*time P_resid*time=2 /overlay  frame;
run;
 
 

