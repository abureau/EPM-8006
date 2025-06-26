/* Code pour convertir les donn�es d'un format large (toutes les mesures d'un m�me sujet sur
   une m�me ligne) en format long (une mesure par ligne)*/

data exercise;
     infile 'exercise.dat';
     input id group y0 y2 y4 y6 y8 y10 y12;
     y=y0; day=0; output;
     y=y4; day=4; output;
     y=y6; day=6; output;
     y=y8; day=8; output;
     y=y12; day=12; output;
     drop y0 y2 y4 y6 y8 y10 y12;

data exercise;
     set exercise;
 

***************************************************;

*   Create additional copy of time variable   *;

***************************************************;
	 /* Cette fois-ci, le d�doublement de la variable temps permet d'avoir une version cat�gorielle
	    pour le mod�le de moyenne et une version continue pour le mod�le de covariance. */
time=day;

 

title1 Unstructure covariance for strength data;
title2 Exercise Therapy Trial;

proc mixed method=reml noclprint=10; 
     class id group time;
     model y = group time group*time / s chisq;
     repeated time / type=un subject=id r rcorr;
 

run;
 

/* Autoregressive Covariance (REML Estimation) */

title1 Autoregressive covariance for strength data;
title2 Exercise Therapy Trial;

proc mixed noclprint=10; 
     class id group time;
     model y = group time group*time / s chisq;
	 /* Sp�cifie un mod�le de corr�lation autor�gressif d'ordre 1.
	 L'option r demande d'afficher la matrice de covariance et l'option rcorr 
	 la matrice de corr�lation. */
     repeated time / type=ar(1) subject=id r rcorr;

run;

/* Heterogeneous Autoregressive Covariance (REML Estimation) */

title1 Heterogeneous autoregressive covariance for strength data;
title2 Exercise Therapy Trial;

proc mixed noclprint=10; 
     class id group time;
     model y = group time group*time / s chisq;
	 /* Sp�cifie un mod�le de corr�lation autor�gressif h�t�rog�ne d'ordre 1.
	 L'option r demande d'afficher la matrice de covariance et l'option rcorr 
	 la matrice de corr�lation. */
     repeated time / type=arh(1) subject=id r rcorr;

run;

/* Exponential Covariance (REML Estimation) */


title1 Exponential covariance for strength data;
title2 Exercise Therapy Trial;

proc mixed noclprint=10; 
     class id group time;
     model y = group time group*time / s chisq;
	 /* Sp�cifie un mod�le de corr�lation spatial � structure exponentielle.
	 L'option r demande d'afficher la matrice de covariance et l'option rcorr 
	 la matrice de corr�lation. */
     repeated time / type=sp(exp)(day) subject=id r rcorr;

run;


