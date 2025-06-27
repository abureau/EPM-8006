data sids;
  input strate antibio cas noncas;
  denom = cas + noncas;
  cards;
  1 0 4 100000
  1 1 4 100000
  2 0 602 663
  2 1 173 134
;
run; 

proc logistic data=sids;
model cas/denom = antibio strate;
run;
