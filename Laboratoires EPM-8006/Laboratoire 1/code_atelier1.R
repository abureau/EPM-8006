#EPM-8006: Concepts avancés en modélisation statistique I
#Professeur: Alexandre Bureau
#Auxiliaire d'enseignement: Loïc Mangnier

#Code R pour le laboratoire 1 d'introduction à R et à SAS
#Objectifs:
#À la fin de cet atelier, l'étudiant sera:
#  -Familier avec R et l'environnement RStudio
#  -Capable de définir un répertoire de travail et importer des données sous format texte (.csv, .txt, .tsv, etc...)
#  -Capable de procéder à des étapes simples de prétraitement, de filtres et de statistiques descriptives
#  -Capable de télécharger un package grâce à la fonction install.packages et d'appeler spécifiquement les fonctions de ce package
#  -Familier avec la notion de programmation fonctionnelle et de functions

##########################################################################################
#Définition du répertoire de travail par défaut grâce à la fonction setwd()
setwd("D:\\EPM-8006\\Laboratoires\\Introduction-SAS-R") #Ce lien est à changer pour indiquer l'accès à vos données
#Comme indiqué pendant le cours attention à bien doubler les backslashs si vous être sous windows
#Importation du fichier de données 
fram1 = read.csv2("data\\fram1.csv", header=TRUE, sep=",") 
#header = TRUE si on s'attend à avoir une ligne d'entête, sep correspond aux delim dans SAS
#fram1 = read.csv(file.choose())

head(fram1) #Affiche les 6 première lignes du fichier
str(fram1) #Affiche le type de chaque variable

dim(fram1) #Affiche le nombre de lignes et de colonnes respectivement
colnames(fram1) #Affiche le nom des colonnes

#Avant d'appliquer les prochaines étapes retirons la colonne d'ID
fram1_sansID = fram1[,-1] #On retire la première colonne, pas optimal
which(colnames(fram1)=='RANDID') #méthode plus robuste pour supprimer une colonne avec un nom connu

summary(fram1_sansID) #Donne tous les statistiques descriptives pour toutes les variables du data.frame

#Conversion des variables SYSBP,DIABP et BMI en numérique
fram1_sansID$SYSBP = as.numeric(fram1_sansID$SYSBP)
fram1_sansID$DIABP = as.numeric(fram1_sansID$DIABP)
fram1_sansID$BMI = as.numeric(fram1_sansID$BMI)

str(fram1_sansID)#Validation du type

#Installation du package mosaic
install.packages("mosaic")
#Importation du package 
library(mosaic)

table(fram1_sansID$DIABETES,fram1_sansID$SEX) #Tableau croisé 2x2
apply(fram1_sansID,2,favstats) #le deuxième argument correspond à si on veut appliquer la fonction (ici favstats) aux lignes (1) ou aux colonnes (2) 

table(fram1_sansID$SEX)/sum(table(fram1_sansID$SEX)) 
#ou 
prop.table(table(fram1_sansID$SEX))

#Inspection graphique des outliers pour la variable SYSBP
boxplot(fram1_sansID$SYSBP)
fram1_sansID[fram1_sansID$SYSBP>290,]

#Retire cette observation du fichier et on créé un nouvel objet
fram1_b = fram1_sansID[-which(fram1_sansID$SYSBP>290),]
#Si on veut supprimer une colonne avec une condition donnée 
#Si on veut supprimer les colonnes avec une moyenne > 450
fram1_sansID[,-which(apply(fram1_sansID, 2, mean)>450)]

#Statistiques chez les hommes et les femmes
with(fram1_b,tapply(SYSBP,SEX,favstats))
boxplot(SYSBP~SEX,fram1_b)

fram1_b$hypertension = fram1_b$SYSBP > 140 | fram1_b$DIABP > 90 
#ou équivalent 
fram1_b$hypertension = ifelse(fram1_b$SYSBP > 140 | fram1_b$DIABP > 90, TRUE,FALSE)

fram1b_ht = fram1_b[fram1_b$hypertension==1,]
apply(fram1b_ht,2,favstats)

#Petit exercice: En réutilisant les fonctions vues précédemment
#Générez les statistiques descriptives pour les personnes ayant de l'hypertension
#chez les hommes et les femmes en utilisant au moins deux approches pour le faire.

#Sauvegarde du data.frame
save(fram1_b,file = "data\\fram1b.RData")


