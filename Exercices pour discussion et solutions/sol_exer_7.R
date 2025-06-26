#**************************************
# 7.1 EXEMPLE DE SOLUTION GEE         *
#**************************************/


### Repertoire de travail
setwd("C:\\Users\\Denis Talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


### Importation des donnees
ds = read.table("milk.data", header = FALSE);
colnames(ds) = c("diet", "cow", "week", "protein");
head(ds);



### Charger les modules necessaires
require(mice);
require(geepack);
require(rms);
require(emmeans);



### Graphiques descriptifs

## Graphique spaghetti
# echantillonnage de 10 sujets
set.seed(4317870);
ids = unique(ds$cow);
samp = sample(ids, 10);

interaction.plot(ds$week[ds$cow %in% samp], 
                 ds$cow[ds$cow %in% samp], 
                 ds$protein[ds$cow %in% samp], type = "l", legend = FALSE,
                 xlab = "Semaine",
                 ylab = "Proteines");

## Graphique des moyenne dans chaque groupe

interaction.plot(ds$week, 
                 ds$diet, 
                 ds$protein, type = "l", legend = F,
                 xlab = "Semaine",
                 ylab = "Proteines", ylim = c(0,5));
legend(x = 2, y = 2, legend = c("1 = orge", "2 = melange", "3 = lupin"), lty = c(1,2,3));

# la quantite de proteine chute rapidement au debut, puis
# reste relativement stable ou augmente selon la diete.
# On devrait exclure l'idee de modeliser une tendance lineaire.
# On pourrait utiliser du lineaire par morceau ou modeliser la relation
# en considerant les semaines de facon categorique;

## Diagramme de dispersion de paires d'observations

# On commence par transformer du format long au format large. 
# Il est utile d'inclure les variables explicatives fixes dans la liste *idvar* pour eviter
# que ces variables soient dupliquees pour chaque visite dans le format large.

ds_large = reshape(ds, timevar = "week", idvar = c("cow", "diet"), direction = "wide");
head(ds_large);
pairs(ds_large[,grep("protein", names(ds_large))], upper.panel = NULL);
# Le graphique suggere une correlation ar(1) : les correlations semblent plus fortes pour les
# semaines raprochees (proches de la diagonales) que celles eloignees.



### GEE

## Solution 1 : Week comme variable categorielle (plusieurs parametres...)

# Puisque j'ai constate que la relation est non lineaire, j'ai
# decide d'inclure week comme un factor (creation d'une indicatrice
# pour chaque semaine).
# Puisqu'il s'agit de donnees continues, j'utilise une distribution de travail normale.
# Puisqu'il s'agit de donnees repetees, j'utilise une matrice de travail autoregressive
# d'ordre 1 (AR(1)).
# Etant donne l'enonce de la question qui est plutot vague, il pourrait sembler
# approprie d'utiliser une approche sequentielle pour analyser les donnees,
# c'est-a-dire de d'abord tester si l'effet de la diete varie dans le temps.
# Si on constate que oui, on devra comparer les dietes pour chaque semaine.
# Si on constate que non, on pourra comparer la moyenne des dietes pour
# toutes les semaines combinees.

# Je trie les observations en ordre chronologique
ds = ds[order(ds$cow, ds$week),];

# Analyse GEE
fit1 = geeglm(protein ~ factor(week) + factor(diet) + factor(week)*factor(diet),
              data = ds, id = cow, corstr = "ar1", family = "gaussian");

# On pourrait essayer de verifier les dfbetas, mais c'est horriblement complique
# avec la quantite de parametres qu'on a... On va simplement regarder les residus
plot(resid(fit1));
# Aucun residu ne semble se distinguer.


# Comparaison des moyennes entre les traitement par semaines
fit1;
# Dans l'ordre les parametres sont :
# 1 = ordonnee
# 2-19 = week2-week19
# 20-21 = diet2-diet3
# 22-39 = diet2*(week2-week19)
# 40-57 = diet3*(week3-week19)
L = matrix(c(0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, rep(0, 18),
             0, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, rep(0, 18),
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
             0, rep(0, 18), 0, 1, rep(0, 18), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
             0, rep(0, 18), 1, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
             0, rep(0, 18), 1, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0,
             0, rep(0, 18), 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1), nrow = 19*3, byrow = TRUE); 
LB = coef(fit1)%*%t(L);
se = sqrt(diag(L%*%vcov(fit1)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
comp = data.frame(estimate = t(LB), LL = t(LL), UL = t(UL), chisq, df = 1, pval);
rownames(comp) = c(paste0("2 vs 1, week = ", 1:19), paste0("3 vs 1, week = ", 1:19), paste0("2 vs 3, week = ", 1:19));
comp;

# Interpretation: 
# Nos analyses indiquent que le contenu en proteines du lait de vache varie en fonction de la diete et du temps
# ecoule depuis le velage. De plus, il semble que l'effet des dietes varie dans le temps. Le contenu en proteines du lait
# a ainsi ete compare entre les dietes a chaque semaine. Les resultats obtenus pour ces analyses demontrent
# la superiorite de la diete a l'orge (1) par rapport a la diete au lupin (3). En effet, le contenu en proteine du lait des vaches
# nourries a l'orge est superieur a celui des vaches nourries au lupin pour les semaines 2, 5, 7, 9 a 19.
# Les comparaisons par semaine de la diete a l'orge vs la diete melangee ou de la diete melangee vs la diete au lupin
# sont cependant plus nuancees en raison d'un manque de puissance statistique.


# Puisqu'on fait de tres nombreuses comparaisons, il pourrait etre pertinent de faire une correction
# pour les tests multiples. Ici, j'utilise la methode de Holm-Bonferroni
comp$padjust = p.adjust(comp$pval, method = "holm");
comp;

# Il ne reste qu'une comparaison qui est statistiquement significative apres cette correction
# 3 vs 1, week = 17 -0.36708 -0.5555 -0.178674 14.5832  1 0.000134 0.00764


## Solution 2 - Approche de regressoin par morceau - plus avance
# Cette partie de programme n'est donnee qu'a titre informatif.
# On va ajuster un modele de Y en fonction de diet et de week
# ou on va supposer une relation lineaire par morceau entre diet*week et
# Y. Un premiere pente correspondra a la relation pour week = 1 jusqu'a week = 4,
# l'autre pente correspondra a la relation pour week = 5 a week = 19.

# Mathematiquement, le modèle a la forme suivante :
# E[Y|diet, week]  = b0 + b1*week + b2*diet_1 + b3*diete_2 + b4*diet_1*week + b5*diet_2*week
#                     + b6*max(0, week - 4) + b7*diet_1*max(0, week - 4) + b8*diet_2*max(0, week - 4).

# Ici, b6 a b8 permettent de representer le changement dans la pente de Y apres la 4e semaine
# pour chacune des dietes. En effet, remarquez que pour les semaines 1 a 4, b6, b7 et b8 seront
# tous multiplies par 0, car max(0, week - 4) = 0. Ainsi, par exemple, la pente de Y en fonction
# de week pour la diete 1 pour ces semaines sera b1 + b4 (pour la diete 1 et pour les semaines 1 a 4,
# lorsque week augmente de 1 unite, Y augmente en moyenne de b1 + b4).
# Pour les semaines suivantes, la pente associee a la diete 1 sera plutot de b1 + b4 + b6 + b7.
# Ainsi, b6 + b7 correspondent au changement de pente pour ces dietes.*/ 

# On va devoir d'abord creer la nouvelle variable pour max(0, week - 4)

ds$max4 = pmax(0, ds$week - 4);

fit2 = geeglm(protein ~ factor(diet) + week + max4 + factor(diet)*week + factor(diet)*max4,
              data = ds, id = cow, corstr = "ar1", family = "gaussian");
fit_r = geeglm(protein ~ factor(diet) + week + max4,
               data = ds, id = cow, corstr = "ar1", family = "gaussian");

# Test d'hypotheses simultane pour verifier si l'effet du traitement varie dans le temps
anova(fit2, fit_r); # p = 0.33, on ne rejette pas que l'effet ne varie pas dans le temps

#  On compare donc les traitements a la semaine du milieu (10)
fit2;
L = matrix(c(0, 1,  0, 0, 0, 10,  0,  6,  0,
             0, 0,  1, 0, 0,  0,  10, 0,  6,
             0, 1, -1, 0, 0, 10, -10, 6, -6), nrow = 3, byrow = TRUE);
LB = coef(fit2)%*%t(L);
se = sqrt(diag(L%*%vcov(fit2)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), LL = t(LL), UL = t(UL), se, chisq, df = 1, pval);

# En moyenne, la diete a l'orge a un contenu en proteine plus eleve que la diete melangee
# (difference de moyennes = 0.11, IC à 95%: 0.02 a 0.20) et que la diete au lupin
# (difference de moyennes = 0.21, IC à 95%: 0.10 a 0.32). La diete melangee est par ailleurs
# superieure a la diete au lupin (difference de moyennes = 0.10, IC à 95%: 0.01 a 0.18).
# Note: J'ai inverse l'ordre des deux premieres comparaisons et donc les signes.

par(mfrow = c(1,2));
interaction.plot(ds$week, 
                 ds$diet, 
                 ds$protein, type = "l", legend = F,
                 xlab = "Semaine",
                 ylab = "Proteines", ylim = c(0,5), main = "obs");
legend(x = 2, y = 2, legend = c("1 = orge", "2 = melange", "3 = lupin"), lty = c(1,2,3));
ds$pred = fit2$fitted;
interaction.plot(ds$week, 
                 ds$diet, 
                 ds$pred, type = "l", legend = F,
                 xlab = "Semaine", ylim = c(0,5), main = "predit");

# Ce n'est pas un modele parfait, mais il semble faire une bonne approximation sans necessiter
# trop de parametres




## Solution 3 - Modelisation de week comme variable continue avec transformation
# Apres plusieurs essais, j'en suis venu a utiliser week et 1/week, ce qui s'ajuste
# plutot bien aux donnees
ds$week_m1 = 1/ds$week;

fit3 = geeglm(protein ~ factor(diet) + week + week_m1 + factor(diet)*week + factor(diet)*week_m1,
              data = ds, id = cow, corstr = "ar1", family = "gaussian");
fit_r = geeglm(protein ~ factor(diet) + week + week_m1,
               data = ds, id = cow, corstr = "ar1", family = "gaussian");

# Test d'hypotheses simultane pour verifier si l'effet du traitement varie dans le temps
anova(fit3, fit_r); # p = 0.59, on ne rejette pas que l'effet ne varie pas dans le temps

# On compare donc les traitements a la semaine du milieu (10)
# Note : le 0.1 = 1/10 pour les termes 1/week
fit3;
L = matrix(c(0, 1,  0, 0, 0, 10,   0, 0.1,    0,
             0, 0,  1, 0, 0,  0,  10,   0,  0.1,
             0, 1, -1, 0, 0, 10, -10, 0.1, -0.1), nrow = 3, byrow = TRUE);
LB = coef(fit3)%*%t(L);
se = sqrt(diag(L%*%vcov(fit3)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), LL = t(LL), UL = t(UL), se, chisq, df = 1, pval);

# En moyenne, la diete a l'orge a un contenu en proteine plus eleve que la diete melangee
# (difference de moyennes = 0.12, IC à 95%: 0.02 a 0.21) et que la diete au lupin
# (difference de moyennes = 0.23, IC à 95%: 0.12 a 0.34). La diete melangee est par ailleurs
# superieure a la diete au lupin (difference de moyennes = 0.11, IC à 95%: 0.02 a 0.20).
# Note: J'ai inverse l'ordre des deux premieres comparaisons et donc les signes.

par(mfrow = c(1,2));
interaction.plot(ds$week, 
                 ds$diet, 
                 ds$protein, type = "l", legend = F,
                 xlab = "Semaine",
                 ylab = "Proteines", ylim = c(0,5), main = "obs");
legend(x = 2, y = 2, legend = c("1 = orge", "2 = melange", "3 = lupin"), lty = c(1,2,3));
ds$pred = fit3$fitted;
interaction.plot(ds$week, 
                 ds$diet, 
                 ds$pred, type = "l", legend = F,
                 xlab = "Semaine", ylim = c(0,5), main = "predit");

# Ce n'est pas un modele parfait, mais il semble faire une bonne approximation sans necessiter
# trop de parametres





### Defi :

# Le defi est tres difficile a relever 
# On va d'abord devoir mettre le jeu de donnees en format
# large;

ds_large = reshape(ds, timevar = "week", idvar = c("cow", "diet"), direction = "wide");
head(ds_large);

mean(apply(ds_large, 1, anyNA)); # 53 % des observations sont incompletes

ds_large$diet = factor(ds_large$diet);

imp = mice(data = ds_large,
           m = 53,
           blocks = list("diet", "protein.1", "protein.2", "protein.3", "protein.4", "protein.5",
                         "protein.6", "protein.7", "protein.8", "protein.9", "protein.10", "protein.11",
                         "protein.12", "protein.13", "protein.14", "protein.15", "protein.16", "protein.17",
                         "protein.18", "protein.19"),
           method = c("polyreg", rep("pmm", 19)),
           seed = 02655399, maxit = 10);
plot(imp, layout = c(5, 6)); 
# J'ai augmente le nombre d'iterations parce que 5 (par defaut) ne semblait pas assez selon le graphique

# Il est difficile d'utiliser l'approche sequentielle 
# avec l'imputation multiple... Supposons qu'on veut simplement
# comparer les moyennes globales entre les dietes pour simplifier

estimates = std.err = matrix(ncol = 3, # nombre de coefficients d'interet
                             nrow = imp$m);
for(i in 1:imp$m){
  ds.i = complete(imp, i);
  ds.long = reshape(ds.i, direction = "long");
  ds.long = ds.long[order(ds.long$cow, ds.long$week),];
  fit = geeglm(protein.1 ~ factor(week) + factor(diet) + factor(diet)*factor(week),
               data = ds.long, id = cow, corstr = "ar1", family = "gaussian");

  L = matrix(c(0, rep(0, 18), 1,  0, rep(1/19, 18), rep(0, 18),
               0, rep(0, 18), 0,  1, rep(0, 18), rep(1/19, 18),
               0, rep(0, 18), 1, -1, rep(1/19, 18), rep(-1/19, 18)), nrow = 3, byrow = TRUE); 
  LB = coef(fit1)%*%t(L);
  se = sqrt(diag(L%*%vcov(fit1)%*%t(L)));
  estimates[i,] = LB;
  std.err[i,] = se;
}

final.results = matrix(nrow = 3, # Nombre de coefficients d'interet
                       ncol = 4);
colnames(final.results) = c("estimates", "se", "LL95", "UL95");
rownames(final.results) = c("2 vs 1", "3 vs 1", "2 vs 3");
for(i in 1:nrow(final.results)){
  res = pool.scalar(estimates[,i], std.err[,i]**2);
  final.results[i,1:2] = c(res$qbar, sqrt(res$t));
}
final.results[,3] = final.results[,1] - 1.96*final.results[,2];
final.results[,4] = final.results[,1] + 1.96*final.results[,2];
final.results;

# Les conclusions sont les memes que sans imputations !



#***************************************
# 7.2 EXEMPLE DE SOLUTION MODELE MIXTE *
#***************************************


### Repertoire de travail
setwd("C:\\Users\\Denis Talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees");


### Importation des donnees
ds = read.table("milk.data", header = FALSE);
colnames(ds) = c("diet", "cow", "week", "protein");
head(ds);



### Charger les modules necessaires
require(nlme);
require(lme4);
require(emmeans);


### Modeles mixtes

# Je vais essayer plusieurs modelisation, les comparer par
# rapport au BIC et interpr�ter l'analyse avec le meilleur ajustement
# selon le BIC.
#  - AR
#  - CS <=> ordonnee a l'origine aleatoire
# Je ne testerai pas UN, parce que ce serait trop lourd 
# (19*20/2 = 190 parametres a estimer!)

# Ici, supposer une pente lineaire aleatoire selon la vache
# n'aurait pas beaucoup de sens puisque la relation entre
# les proteines et les semaines ne semble pas du tout lineaire.
# On pourrait cependant utiliser une ordonnee a l'origine aleatoire, une
# pente aleatoire et un terme quadratique aleatoire. Il faudrait
# alors creer une variable week_continue qu'on ne considere pas
# comme factor

 
# Comparaison de differents modeles
# AR(1)
ds = ds[order(ds$cow, ds$week),];
ds$week_cat = factor(ds$week);
ds$diet = factor(ds$diet);
fit1 = gls(protein ~  diet*week_cat, correlation = corAR1(form = ~ week|cow), data = ds);
fit2 = gls(protein ~  diet*week_cat, correlation = corCompSymm(form = ~ week|cow), data = ds);
fit3 = lmer(protein ~ diet*week_cat + (1 + week + I(week**2)|cow), data = ds);
# On rencontre des problemes de convergence avec le modele 3...

BIC(fit1); BIC(fit2);
# On choisit le modele 1


# Verification des hypotheses... un peu...
plot(resid(fit1));
# Tout semble ok

# Tableau d'ANOVA
anova(fit1);

em = emmeans(fit1, ~diet, adjust = "none");
pm = as.data.frame(pairs(em, adjust = "none"));
pm$LL = pm$estimate - 1.96*pm$SE;
pm$UL = pm$estimate + 1.96*pm$SE;
pm;

em2 = emmeans(fit1, ~diet*week_cat);
pm2 = as.data.frame(pairs(em2, by = "week_cat", adjust = "none"));
pm2$LL = pm2$estimate - 1.96*pm2$SE;
pm2$UL = pm2$estimate + 1.96*pm2$SE;
pm2;




# Interpretation: 
# Nos analyses indiquent que le contenu en proteines du lait de vache
# varie en fonction de la diete et du temps ecoule depuis le velage.
# Cependant, les analyses effectuees ne permettent pas d'identifier
# une variation dans l'effet de la diete sur le contenu en proteines
# en fonction du temps ecoule depuis le velage. 
# En moyenne, le contenu en proteine du lait des vaches nourries a l'orge
# est superieur a celui des vaches nourries 
# au lupin (0.22 IC a 95%: 0.14 a 0.31) ou avec un melange d'orge et de lupin
# (0.11, IC a 95%: 0.02 a 0.19). Les vaches nourries selon le melange
# donnent egalement un lait plus riche en proteine
# que les vaches nourries au lupin (0.12, IC a 95%: 0.04 a 0.20).

# Le contenu en proteines du lait a egalement ete compare a chaque semaine.
# Les resultats obtenus pour ces analyses confirment
# la superiorite de la diete a l'orge par rapport a la diete au lupin.
# En effet, le contenu en proteine du lait des vaches nourries a l'orge
# est superieur a celui des vaches nourries au lupin pour les
# semaines 2, 5 ainsi que 7, 9 a 17. Les comparaisons par
# semaine de la diete a l'orge vs la diete melangee ou de la diete melangee
# vs la diete au lupin sont cependant plus nuances
# en raison d'un manque de puissance statistique.*/

# Remarquons en conclusion que les resultats avec GENMOD avec
# ou sans imputation ainsi que ceux avec PROC MIXED 
# sont tres similaires.

### Defi :

# Etant donne que les modeles mixtes sont robustes aux donnees MAR,
# il n'y a rien de plus a faire;





#***************************
# 7.3 EXEMPLE DE SOLUTION  *
#**************************/

### Chargement des modules necessaires
require(geepack);
require(rms); # pour les vifs


### Importation des donnees
ds = read.csv("C:\\Users\\Denis Talbot\\Dropbox\\Travail\\Cours\\EPM8006\\Donnees\\fram_complet_large.csv");
head(ds);


### Creation des variables de censure
ds$C2 = with(ds, ifelse(is.na(HEARTRTE2) & is.na(AGE2) & is.na(SEX2) &
                        is.na(CURSMOKE2) & is.na(CIGPDAY2) & is.na(EDUC2) &
                        is.na(HEARTRTE3) & is.na(AGE3) & is.na(SEX3) &
                        is.na(CURSMOKE3) & is.na(CIGPDAY3) & is.na(EDUC3), 1, 0));
ds$C3 = with(ds, ifelse(is.na(HEARTRTE3) & is.na(AGE3) & is.na(SEX3) &
                        is.na(CURSMOKE3) & is.na(CIGPDAY3) & is.na(EDUC3), 1, 0));


with(ds, list(table(C2), table(C3), table(C2, C3)));
# On avait 4434 sujets,
# on s'attendrait a 4434*3 = 13302 observations
# on avait 11167 observations, donc 1675 observations perdues
# on a 447 + 1171 = 1618 observations "censurees" selon notre definition
# Donc la majorite des observations perdues sont considerees par notre definition,
# une minorite sont des sujets manquants a la period 2 et presents a la period 3.*/
 

### Regression logistiques pour la censure
fitc2 = glm(C2 ~ HEARTRTE1 + AGE1 + SEX1 + CURSMOKE1 + CIGPDAY1 + factor(EDUC1),
            data = ds, family = "binomial");
fitc3 = glm(C3 ~ HEARTRTE2 + AGE2 + SEX2 + CURSMOKE2 + CIGPDAY2 + factor(EDUC2),
            data = ds, family = "binomial", subset = C2 == 0);
 

### Calcul des poids
# Pour faciliter la suite, une strategie est de predire les probabilites
# de censure pour toutes les vaches
pred2 = 1 - predict(fitc2, newdata = ds, type = "res");
pred3 = 1 - predict(fitc3, newdata = ds, type = "res");

ds$w2 = 1/pred2;
ds$w3 = ds$w2*1/pred3;

# Note : J'ai calcule les poids pour tous les sujets, censures ou non, 
#        mais on ne doit utiliser que ceux non-censures
ds$w2[ds$C2 == 1] = 0;
ds$w3[ds$C3 == 1] = 0;

### Verifier que la somme des poids +/- la meme que le n (4434 ici)
with(ds, list(sum(w2, na.rm = TRUE), sum(w3, na.rm = TRUE)));

# La somme des poids < 4434, probablement
#  en raison des autres donnees manquantes;

# Creation d'une base longue
long1 = ds[ds$C2 == 0,];
long1$HEARTRTE = long1$HEARTRTE2;
long1$w = long1$w2;
long1$CURSMOKE = long1$CURSMOKE2;
long1$CIGPDAY = long1$CIGPDAY2;
long1$AGE = long1$AGE1;
long1$EDUC = long1$EDUC1;
long1$SEX = long1$SEX1;
long1$HEARTRTE0 = long1$HEARTRTE1;
long1$PERIOD = 2;

long2 = ds[ds$C3 == 0,];
long2$HEARTRTE = long2$HEARTRTE3;
long2$w = long2$w3;
long2$CURSMOKE = long2$CURSMOKE3;
long2$CIGPDAY = long2$CIGPDAY3;
long2$AGE = long2$AGE2;
long2$EDUC = long2$EDUC2;
long2$SEX = long2$SEX2;
long2$HEARTRTE0 = long2$HEARTRTE2;
long2$PERIOD = 3;

long = rbind(long1, long2);
long$unique_id = 1:nrow(long);


### Modelisation
# Notes : - J'utilise une matrice de travail independance parce que 
#           ce sont des donnees observationnelles avec exposition
#           qui varie;
#         - Je modelise les variables continues de facon lineaire, mais
#           On aurait pu decider d'utiliser des splines. Pour CIGPDAY,
#           ca rendrait l'interpretation plus difficile par contre;

long.na = na.exclude(long);

fit = geeglm(HEARTRTE ~ CURSMOKE + CIGPDAY + AGE + factor(EDUC) + SEX +
                        HEARTRTE0 + PERIOD,
             data = long.na, weights = w, family = "gaussian", id = RANDID,
             corstr = "independence");

### Verification des hypotheses
## Relation residuelle
plot(x = long.na$CIGPDAY, y = fit$resid);
lines(lowess(y = fit$resid, x = long.na$CIGPDAY), col = "brown", lwd = 3);
abline(h = 0, lwd = 2, col = "purple");

plot(x = long.na$AGE, y = fit$resid);
lines(lowess(y = fit$resid, x = long.na$AGE), col = "brown", lwd = 3);
abline(h = 0, lwd = 2, col = "purple");

plot(x = long.na$HEARTRTE0, y = fit$resid);
lines(lowess(y = fit$resid, x = long.na$HEARTRTE0), col = "brown", lwd = 3);
abline(h = 0, lwd = 2, col = "purple");

# Aucune relation residuelle evidente, mais une valeur
# extreme pour HEARTRTE0;


## Donnees influentes
plot(fit$resid);
long.na[which.max(fit$resid),]; # unique_id = 523 est celui avec le residu eleve
 

## Multicollinearite;
vif(fit); # ok


### Analyse des resultats 
# Comparaisons de moyennes
# Je decide de comparer Fumeurs 5, Fumeurs 15 et Fumeurs 25 vs non-fumeurs
names(fit$coef);
L = matrix(c(0, 1,  5, 0, 0, 0, 0, 0, 0, 0,
             0, 1, 15, 0, 0, 0, 0, 0, 0, 0,
             0, 1, 25, 0, 0, 0, 0, 0, 0, 0), nrow = 3, byrow = TRUE);
LB = coef(fit)%*%t(L);
se = sqrt(diag(L%*%vcov(fit)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), LL = t(LL), UL = t(UL), chisq, df = 1, pval);
# Avec toutes les obs
#    estimate         LL       UL     chisq df         pval
# 1 0.4838233 -0.3231354 1.290782  1.380966  1 2.399366e-01
# 2 1.1891845  0.5638793 1.814490 13.893975  1 1.934175e-04
# 3 1.8945458  1.2300777 2.559014 31.230148  1 2.291792e-08

# On retire unique_id = 523
fit = geeglm(HEARTRTE ~ CURSMOKE + CIGPDAY + AGE + factor(EDUC) + SEX +
                        HEARTRTE0 + PERIOD,
             data = long.na, weights = w, family = "gaussian", id = RANDID,
             corstr = "independence", subset = unique_id != 523);
L = matrix(c(0, 1,  5, 0, 0, 0, 0, 0, 0, 0,
             0, 1, 15, 0, 0, 0, 0, 0, 0, 0,
             0, 1, 25, 0, 0, 0, 0, 0, 0, 0), nrow = 3, byrow = TRUE);
LB = coef(fit)%*%t(L);
se = sqrt(diag(L%*%vcov(fit)%*%t(L)));
LL = LB - 1.96*se;
UL = LB + 1.96*se;
chisq = (t(LB)/se)**2;
pval = pchisq(chisq, df = 1, lower.tail = FALSE);
data.frame(estimate = t(LB), LL = t(LL), UL = t(UL), chisq, df = 1, pval);

#    estimate         LL       UL     chisq df         pval
# 1 0.5367628 -0.2633857 1.336911  1.728764  1 1.885688e-01
# 2 1.2439452  0.6279022 1.859988 15.663635  1 7.566509e-05
# 3 1.9511275  1.2959206 2.606334 34.066421  1 5.326253e-09

# Les resultats ne changent pas beaucoup.
# Le tabagisme est associe a une augmentation du rythme
# cardiaque selon une relation dose-reponse.

