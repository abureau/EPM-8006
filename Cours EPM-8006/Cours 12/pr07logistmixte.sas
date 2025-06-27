data infection; 
      input clinic t x n; 
      datalines; 
   1 1 11 36 
   1 0 10 37 
   2 1 16 20  
   2 0 22 32 
   3 1 14 19 
   3 0  7 19 
   4 1  2 16 
   4 0  1 17 
   5 1  6 17 
   5 0  0 12 
   6 1  1 11 
   6 0  0 10 
   7 1  1  5 
   7 0  1  9 
   8 1  4  6 
   8 0  6  7 
   run;

   /* Estimation d'un modèle logistique mixte avec ordonnée à l'origine 
      aléatoire à l'aide de proc glimmix

   Attention! Par défaut, proc glimmix utilise une pseudo-vraisemblance comme critère d'estimation, qui
   représente une approximation plus ou moins bonne de la vraisemblance. Pour l'estimation du maximum
   de vraisemblance, il faut spécifier method=quad ou method=laplace. La méthode de quadrature (method=quad)
   est la même utilisée par proc nlmixed.*/
   proc glimmix data=infection method=quad;
     /* La spécification de la réponse sous la forme nombre d'événements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas nécessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin link=logit  oddsratio(at t=0);
   random intercept / subject=clinic;
   run;

   /* Modèle logistique marginal estimé par équations d'estimation généralisées, 
      donne des estimations de coefficients atténuées

      Attention! Seul le type=ind fonctionne avec le format de données nombre d'événements/total.
   */
   proc genmod data=infection;
     class clinic;
     model x/n = t / dist=bin link=logit;
     repeated subject=clinic / type=ind;
	 estimate "traitement" t 1 /exp;
   run;

   /* Modèle log-binomial mixte */
   proc glimmix data=infection method=quad;
     /* La spécification de la réponse sous la forme nombre d'événements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas nécessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin link=log;
   random intercept / subject=clinic;
   estimate "traitement" t 1 /exp;
   run;


   /* Modèle log-binomial marginal estimé par équations d'estimation généralisées, 
      donne des estimations de coefficients proches de celles du modèle log-binomial mixte

      Attention! Seul le type=ind fonctionne avec le format de données nombre d'événements/total.
   */
   proc genmod data=infection;
     class clinic;
     model x/n = t / dist=bin link=log;
     repeated subject=clinic / type=ind;
	 estimate "traitement" t 1 /exp;
   run;

   /* Estimation d'un modèle logistique mixte avec ordonnée à l'origine 
      et effet du traitement aléatoire à l'aide deproc glimmix    
    
   Attention! Par défaut, proc glimmix utilise une pseudo-vraisemblance comme critère d'estimation, qui
   représente une approximation plus ou moins bonne de la vraisemblance. Pour l'estimation du maximum
   de vraisemblance, il faut spécifier method=quad ou method=laplace. La méthode de quadrature (method=quad)
   est la même utilisée par proc nlmixed.*/
   proc glimmix data=infection method=quad;
   /* La spécification de la réponse sous la forme nombre d'événements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas nécessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin oddsratio(at t=0);
   /* Il est nécessaire de spécifier type=un pour estimer la covariance des effets aléatoires.
      La structure simple par défaut suppose une covariance de 0, ce qui est indésirable. */
   random intercept t / type=un subject=clinic g gcorr;
   run;

   /* Modèle log-binomial mixte.
      L'estimation par maximum de vraisemblance échoue, */
   proc glimmix data=infection method=laplace;
   model x/n = t / s chisq dist=bin link=log;
   random intercept t / type=un subject=clinic g gcorr;
   run;
   /*il faut donc recourir à une approximation
      par quasi-vraisemblance pénalisée restreinte */
   proc glimmix data=infection method=rspl infocrit=PQ;
   /* La spécification de la réponse sous la forme nombre d'événements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas nécessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin link=log;
   /* Il est nécessaire de spécifier type=unstr pour estimer la covariance des effets aléatoires.
      La structure simple par défaut suppose une covariance de 0, ce qui est indésirable. */
   random intercept t / type=un subject=clinic g gcorr;
   estimate "traitement" t 1 /exp;
   run;




 /* Même analyse avec proc nlmixed  */
proc nlmixed data=infection df=10000; 
      parms beta0=-1 beta1=0.5 s2u=5 s2v=5 suv=0;
      eta = beta0 + beta1*t + u + v*t; 
      expeta = exp(eta); 
      p = expeta/(1+expeta); 
      model x ~ binomial(n,p); 
      random u v ~ normal([0,0],[s2u,suv,s2v]) subject=clinic; 
   run;

