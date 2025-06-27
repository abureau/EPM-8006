/* Lecture du fichier de donn�es en format texte */
libname donnees "C:\Users\etudiant\Documents\EPM-8006\donnees";

Data donnees.Dental_wide;
     infile 'dental.dat';
     input id gender$ y1 y2 y3 y4;
run;

/* Calcul de covariance et de corr�lation, s�par�ment chez les gar�ons et les filles */
proc corr data=donnees.Dental_wide cov;
var y1 y2 y3 y4;
by gender;
run;

/* Code pour convertir les donn�es d'un format large (toutes les mesures d'un m�me sujet sur
   une m�me ligne) en format long (une mesure par ligne)*/
Data Dental3;
set donnees.Dental_wide;
     y=y1; year=8; output;
     y=y2; year=10; output;
     y=y3; year=12; output;
     y=y4; year=14; output;
     drop y1 y2 y3 y4;
Run;

/* D�doublement de la variable temps permet d'avoir une version cat�gorielle
pour le mod�le de moyenne et une version continue pour le mod�le de covariance. */
Data Dental3;
Set Dental3;
time=year;
Run;

/* Estimation de divers mod�les de covariance, en sp�cifiant le mod�le satur� pour
   la moyenne */

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance non-structur�e */
repeated time / type=unstr subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* Covariance �changeable h�t�rog�ne */
repeated time / type=csh subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance �changeable */
repeated time / type=cs subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* Covariance autor�gressive h�t�rog�ne */
repeated time / type=arh(1) subject=id r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* Covariance autor�gressive */
repeated time / type=ar(1) subject=id r rcorr;
run;

/* Essai de l'option group */
Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance non-structur�e par sexe*/
repeated time / type=unstr subject=id group=gender r rcorr;
run;

Proc mixed method=reml noclprint=10 order=data;
class id gender time;
model y=gender time gender*time / s chisq;
/* covariance �changeable par sexe*/
repeated time / type=cs subject=id group=gender r rcorr;
run;
