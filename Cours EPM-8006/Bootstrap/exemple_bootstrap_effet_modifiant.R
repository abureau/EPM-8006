### Repertoire de travail
setwd("C:\\Users\\Denis talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


### Importation des donnees
ds = read.csv("fram1.csv");
head(ds);


### Charger les modules necessaires
require(boot);
#source("rerifun.R");


### Fonction d'analyse 
# Il faut definir une fonction qui calcule le RERI en prenant un premier
# argument *data* et un deuxieme argument qui peut prendre differentes formes.
# L'option par defaut est un vecteur d'indices definissant un echantillon bootstrap.

RERI.i = function(data, indices){
  bd = data[indices,];
  fit = glm(DIABETES ~ CURSMOKE + SEX + CURSMOKE*SEX + AGE + BMI + SYSBP + DIABP,
            data = bd, family = poisson(link = "log"));
  reri.est = RERI.fun(fit, coef.exp = 2, coef.modif = 3, coef.inter = 8);
  return(reri.est$RERI$RERI);
}

# Une autre option est que le deuxieme argument soit un poids pour chaque observation,
# qui prend les valeurs 0, 1/n, 2/n, ... selon le nombre de fois ou l'observation se
# retrouve dans l'echantillon bootstrap

RERI.w = function(data, w){
  fit = glm(DIABETES ~ CURSMOKE + SEX + CURSMOKE*SEX + AGE + BMI + SYSBP + DIABP,
            data = data, family = poisson(link = "log"), weights = w);
  reri.est = RERI.fun(fit, coef.exp = 2, coef.modif = 3, coef.inter = 8);
  return(reri.est$RERI$RERI);
}

# Test des fonctions RERI.i et RERI.w
RERI.i(ds, indices = 1:nrow(ds));
RERI.w(ds, w = rep(1, nrow(ds)));


### Exécution du bootstrap avec calcul du RERI

# On specifie 1000 echantillons bootstrap. L'argument *stype="i"* precise que la fonction
# *boot* doit passer les indices des observations appartenant a un echantillon bootstrap a
# notre fonction appelee ici *RERI*. C'est l'option par defaut.

set.seed(1001);
RERIsexe_tabac.boot = boot(ds, RERI.i, R = 1000, stype = "i");
RERIsexe_tabac.boot;

# On peut aussi specifier *stype="w"* pour utiliser la fonction *RERIw*.
set.seed(1001);
RERIsexe_tabac.bootw = boot(ds, RERI.w, R = 1000, stype = "w");
RERIsexe_tabac.bootw;

# Examen de la distribution du RERI
hist(RERIsexe_tabac.boot$t)

# On calcule divers types d'intervalles de confiance bootstrap avec la fonction *boot.ci*.
RERIsexe_tabac.IC = boot.ci(RERIsexe_tabac.boot, index = 1, type = "perc");
RERIsexe_tabac.IC;
# (-2.738, -0.200 )  

# Le calcul de l'intervalle BCa echoue sur l'objet obtenu avec
# la fonction qui prend les indices des observations.
RERIsexe_tabac.IC = boot.ci(RERIsexe_tabac.boot, index = 1, type = "bca");

# Par contre, le calcul reussi sur l'objet obtenu avec la fonction qui prend des poids.
RERIsexe_tabac.IC = boot.ci(RERIsexe_tabac.bootw, index = 1, type = "bca");
RERIsexe_tabac.IC;
# (-2.570, -0.122 )  