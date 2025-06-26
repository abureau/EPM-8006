/* Lecture du fichier de données en format texte */
libname donnees "C:\Users\etudiant\Documents\EPM-8006\donnees";

Data donnees.Dental_wide;
     infile 'dental.dat';
     input id gender$ y1 y2 y3 y4;
run;

/* Calcul de covariance et de corrélation, séparément chez les garçons et les filles */
proc corr data=donnees.Dental_wide cov;
var y1 y2 y3 y4;
by gender;
run;

/* Code pour convertir les données d'un format large (toutes les mesures d'un même sujet sur
   une même ligne) en format long (une mesure par ligne)*/
Data Dental3;
set donnees.Dental_wide;
     y=y1; year=8; output;
     y=y2; year=10; output;
     y=y3; year=12; output;
     y=y4; year=14; output;
     drop y1 y2 y3 y4;
Run;

/* Dédoublement de la variable temps permet d'avoir une version catégorielle
pour le modèle de moyenne et une version continue pour le modèle de covariance. */
Data Dental3;
Set Dental3;
time=year;
Run;

/* Estimation de divers modèles de covariance, en spécifiant le modèle saturé pour
   la moyenne */

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance non-structurée */
repeated time / type=unstr subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* Covariance échangeable hétérogène */
repeated time / type=csh subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance échangeable */
repeated time / type=cs subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* Covariance autorégressive hétérogène */
repeated time / type=arh(1) subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* Covariance autorégressive */
repeated time / type=ar(1) subject=id r rcorr;
run;

/* Essai de l'option group */
Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance non-structurée par sexe*/
repeated time / type=unstr subject=id group=gender r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance échangeable par sexe*/
repeated time / type=cs subject=id group=gender r rcorr;
run;
