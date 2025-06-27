/* Examen des r�sidus du mod�le de la croissance de capacit�
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

/* On sp�cifie l'option covtest pour demander les erreurs-types 
   pour les param�tres de covariance. SAS effectue en m�me temps
   les tests de Wald, mais il ne faut pas s'y fier. */
proc mixed data=fev method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel;  
     class id;
     model logfev1 = age loght baseage logbht / s chisq residual vciry outpm=fevp;
     random intercept age / subject=id type=un g gcorr v=35 vcorr=35; 
run;

/* Identification des r�sidus extr�mes */
data fevaber;
  set fevp;
  if scaledresid < -4;
run;

/* On enl�ve le r�sidu le plus extr�me et on refait l'analyse. */
data fev2;
  set fev;
*if (id ne 197 and id ne 30 and id ne 118 and id ne 120 and id ne 131 and id ne 246);
if (id ne 197 );
run;

/* Cr�ation de variables pour changement de pente � 12 et � 15 ans */
data fev2;
  set fev2;
  age12 = max(age-12,0);
  age15 = max(age-15,0);
run;

/* On sp�cifie l'option covtest pour demander les erreurs-types 
   pour les param�tres de covariance. SAS effectue en m�me temps
   les tests de Wald, mais il ne faut pas s'y fier. */
proc mixed data=fev2 method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel;  
     class id;
     model logfev1 = age loght baseage logbht / s chisq residual vciry outpm=fevp;
     random intercept age / subject=id type=un g gcorr v=35 vcorr=35; 
run;

/* Comme SAS retourne la r�ponse transform�e au lieu de la valeur moyenne pr�dite
   transform�e, on calcule la valeur moyenne pr�dite
   transform�e en soustrayant les r�sidus transform�s
   de la r�ponse transform�e. */
data fevp;
  set fevp;
  predt = scaleddep - scaledresid;
run;
/* Lissage avec proc loess */

/* Lissage des r�sidus bruts en fonction de la moyenne pr�dite. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model resid = pred / clm select=df1(4);
run;

/* Lissage des r�sidus transform�s en fonction de la moyenne pr�dite transform�e. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model scaledresid = predt / clm select=df1(4);
run;

/* Lissage des r�sidus bruts en fonction de l'�ge. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model resid = age / clm select=df1(4);
run;

/* Lissage des r�sidus transform�s en fonction de l'�ge. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model scaledresid = age / clm select=df1(4);
run;

/* Lissage des r�sidus bruts en fonction de la log taille. */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model resid = loght / clm select=df1(4);
run;

/* Lissage des r�sidus transform�s en fonction de la log taille */
proc loess data=fevp plots(maxpoints=none)=fitplot;
   model scaledresid = loght / clm select=df1(4);
run;

/* Mod�lisation de l'�ge en 3 segments */
proc mixed data=fev2 method=reml noclprint=10 covtest plots=residualpanel(marginal) plots=vcirypanel;  
     class id;
     model logfev1 = age age12 age15 loght baseage logbht / s chisq residual vciry outpm=fevp;
     random intercept age age12 age15 / subject=id type=un g gcorr v=35 vcorr=35; 
run;
