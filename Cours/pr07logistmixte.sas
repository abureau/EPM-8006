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

   /* Estimation d'un mod�le logistique mixte avec ordonn�e � l'origine 
      al�atoire � l'aide de proc glimmix

   Attention! Par d�faut, proc glimmix utilise une pseudo-vraisemblance comme crit�re d'estimation, qui
   repr�sente une approximation plus ou moins bonne de la vraisemblance. Pour l'estimation du maximum
   de vraisemblance, il faut sp�cifier method=quad ou method=laplace. La m�thode de quadrature (method=quad)
   est la m�me utilis�e par proc nlmixed.*/
   proc glimmix data=infection method=quad;
     /* La sp�cification de la r�ponse sous la forme nombre d'�v�nements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas n�cessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin link=logit  oddsratio(at t=0);
   random intercept / subject=clinic;
   run;

   /* Mod�le logistique marginal estim� par �quations d'estimation g�n�ralis�es, 
      donne des estimations de coefficients att�nu�es

      Attention! Seul le type=ind fonctionne avec le format de donn�es nombre d'�v�nements/total.
   */
   proc genmod data=infection;
     class clinic;
     model x/n = t / dist=bin link=logit;
     repeated subject=clinic / type=ind;
	 estimate "traitement" t 1 /exp;
   run;

   /* Mod�le log-binomial mixte */
   proc glimmix data=infection method=quad;
     /* La sp�cification de la r�ponse sous la forme nombre d'�v�nements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas n�cessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin link=log;
   random intercept / subject=clinic;
   estimate "traitement" t 1 /exp;
   run;


   /* Mod�le log-binomial marginal estim� par �quations d'estimation g�n�ralis�es, 
      donne des estimations de coefficients proches de celles du mod�le log-binomial mixte

      Attention! Seul le type=ind fonctionne avec le format de donn�es nombre d'�v�nements/total.
   */
   proc genmod data=infection;
     class clinic;
     model x/n = t / dist=bin link=log;
     repeated subject=clinic / type=ind;
	 estimate "traitement" t 1 /exp;
   run;

   /* Estimation d'un mod�le logistique mixte avec ordonn�e � l'origine 
      et effet du traitement al�atoire � l'aide deproc glimmix    
    
   Attention! Par d�faut, proc glimmix utilise une pseudo-vraisemblance comme crit�re d'estimation, qui
   repr�sente une approximation plus ou moins bonne de la vraisemblance. Pour l'estimation du maximum
   de vraisemblance, il faut sp�cifier method=quad ou method=laplace. La m�thode de quadrature (method=quad)
   est la m�me utilis�e par proc nlmixed.*/
   proc glimmix data=infection method=quad;
   /* La sp�cification de la r�ponse sous la forme nombre d'�v�nements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas n�cessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin oddsratio(at t=0);
   /* Il est n�cessaire de sp�cifier type=un pour estimer la covariance des effets al�atoires.
      La structure simple par d�faut suppose une covariance de 0, ce qui est ind�sirable. */
   random intercept t / type=un subject=clinic g gcorr;
   run;

   /* Mod�le log-binomial mixte.
      L'estimation par maximum de vraisemblance �choue, */
   proc glimmix data=infection method=laplace;
   model x/n = t / s chisq dist=bin link=log;
   random intercept t / type=un subject=clinic g gcorr;
   run;
   /*il faut donc recourir � une approximation
      par quasi-vraisemblance p�nalis�e restreinte */
   proc glimmix data=infection method=rspl infocrit=PQ;
   /* La sp�cification de la r�ponse sous la forme nombre d'�v�nements/nombre d'observations
      implique une distribution binomiale. Il n'est donc pas n�cessaire d'ajouter l'option dist=bin */ 
   model x/n = t / s chisq dist=bin link=log;
   /* Il est n�cessaire de sp�cifier type=unstr pour estimer la covariance des effets al�atoires.
      La structure simple par d�faut suppose une covariance de 0, ce qui est ind�sirable. */
   random intercept t / type=un subject=clinic g gcorr;
   estimate "traitement" t 1 /exp;
   run;




 /* M�me analyse avec proc nlmixed  */
proc nlmixed data=infection df=10000; 
      parms beta0=-1 beta1=0.5 s2u=5 s2v=5 suv=0;
      eta = beta0 + beta1*t + u + v*t; 
      expeta = exp(eta); 
      p = expeta/(1+expeta); 
      model x ~ binomial(n,p); 
      random u v ~ normal([0,0],[s2u,suv,s2v]) subject=clinic; 
   run;

