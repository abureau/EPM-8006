
/* MIT Growth and Development Study
 

 

Linear Mixed Effects Model (Random Intercept and Slopes) */

 

 

data fat;
     infile 'fat.dat';
     input id age agemen time pbf;

/* Cr�ation d'une variable pour le changement de pente apr�s temps 0 */
time_0=max(time,0);
run;

title1 Mixed Effects Model for Percent Body Fat with Random Intercept and Slopes before and after Menarche;
title2 MIT Growth and Development Study;

ods graphics on;

/* On sp�cifie l'option covtest pour demander les erreurs-types 
   pour les param�tres de covariance. SAS effectue en m�me temps
   les tests de Wald, mais il ne faut pas s'y fier. 

   l'option plots=residualpanel produit des graphiques des r�sidus bruts et "studentis�s",
   alors que plots=vcirypanel produit des graphiques des r�sidus transform�s ("r�sidus mis 
   � l'�chelle" dans la terminologie de SAS.) */
proc mixed method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel; 
     class id;
     /* L'option residual demande de produire les residus bruts et "studentis�s".
	    L'option vciry demande de produre les residus transform�s.
	    Ces r�sidus, les valeurs transform�es de la r�ponse et les valeurs pr�dites 
	    de la moyenne sont �crites dans le fichier sp�cifi� avec l'option outpm= .*/
     model pbf = time time_0 / s chisq residual vciry outpm=fatp;
     random intercept time time_0 / subject=id type=un g gcorr v vcorr; 
run;

/* Comme SAS retourne la r�ponse transform�e au lieu de la valeur moyenne pr�dite
   transform�e, on calcule la valeur moyenne pr�dite
   transform�e en soustrayant les r�sidus transform�s
   de la r�ponse transform�e. */
data fatp;
  set fatp;
  predt = scaleddep - scaledresid;
run;

/* Lissage avec proc loess */

/* Lissage des r�sidus bruts en fonction de la moyenne pr�dite. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model resid = pred / clm select=df1(4);
run;

/* Lissage des r�sidus transform�s en fonction de la moyenne pr�dite transform�e. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model scaledresid = predt / clm select=df1(4);
run;

/* Lissage des r�sidus bruts en fonction du temps. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model resid = time / clm select=df1(4);
run;

/* Lissage des r�sidus transform�s en fonction du temps. */
proc loess data=fatp plots(maxpoints=none)=fitplot;
   model scaledresid = time / clm select=df1(4);
run;

/* Lissage avec prog gam */

/* Lissage des r�sidus bruts en fonction de la moyenne pr�dite. */
proc gam data=fatp plots=all;
   model resid = loess(pred,df=4);
   output out=fatb p uclm lclm;
run;

/* Lissage des r�sidus transform�s en fonction de la moyenne pr�dite transform�e. */
proc gam data=fatp;
   model scaledresid = loess(predt,df=4);
   output out=fatt p uclm lclm;
run;


/* Lissage des r�sidus bruts en fonction du temps. */
proc gam data=fatp;
   model resid = loess(time,df=4);
   output out=fatbt p uclm lclm;
run;

/* Lissage des r�sidus transform�s en fonction du temps. */
proc gam data=fatp;
   model scaledresid = loess(time,df=4);
   output out=fattt p uclm lclm;
run;

/* Graphiques */

/* tri en ordre croissant d'�ge pour faire le graphique */
 proc sort data=fatt out=plot_fatt; by predt; run;

proc gplot data=plot_fatt;
/* graphique des r�sidus transform�s vs. le temps */
  plot scaledresid*predt P_scaledresid*predt=2 /overlay  frame;
run;
 
/* tri en ordre croissant d'�ge pour faire le graphique */
 proc sort data=fatb out=plot_fatb; by pred; run;

proc gplot data=plot_fatb;
/* graphique des r�sidus bruts vs. le temps */
  plot resid*pred P_resid*pred=2 /overlay  frame;
run;
 

/* tri en ordre croissant d'�ge pour faire le graphique */
 proc sort data=fattt out=plot_fattt; by time; run;

proc gplot data=plot_fattt;
/* graphique des r�sidus transform�s vs. le temps */
  plot scaledresid*time P_scaledresid*time=2 /overlay  frame;
run;
 
/* tri en ordre croissant d'�ge pour faire le graphique */
 proc sort data=fatbt out=plot_fatbt; by time; run;

proc gplot data=plot_fatbt;
/* graphique des r�sidus bruts vs. le temps */
  plot resid*time P_resid*time=2 /overlay  frame;
run;
 
 

