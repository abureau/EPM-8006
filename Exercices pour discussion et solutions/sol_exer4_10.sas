libname modeli " C:\Users\etudiant\Documents\EPM-8006\donnees";

data exe11_02; set modeli.chp11;

if (fume=. or pdsm=. or pdse=. or taille=. or ag=.) then delete;

if        pdse<2500 then y=1;
if 2500<=pdse<3000  then y=2;
if 3000<=pdse  then y=3;
run;

proc logistic;
 model y=fume;
run;


proc logistic;
 model y=fume pdsm taille ag;
run;

/* En ajustant pour tous les facteurs (AGE, TAILLE et PDSM), le rapport de cotes est de 2,92 avec un intervalle de confiance à 95% de [2,18   -  3,89]. Sans ajustement, le rapport de cotes est de 2,99 avec un intervalle de confiance à 95% de [2,25   -  3,96]. 
Si on admet que les naissances dans les deux tranches de poids les plus bas sont rares, alors tout changement du RC serait dû aux facteurs de confusion. On voit ici que l'âge, la taille et le poids de la mère ne confondent pas le RC.

À partir de ce modèle, on conclut que « pour tout seuil choisi de poids à la naissance sur cette échelle ordinale,  la cote des risques d’avoir un bébé d’un poids inférieur à ce seuil est 3 fois plus grande chez les mères fumeuses que chez les mères non fumeuses ».*/
