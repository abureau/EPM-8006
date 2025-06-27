/* Load the data */
proc import datafile="../donnees/chp09.csv" out=chp09 dbms=csv replace;
    getnames=yes;
run;

/* Split the data into training and testing sets */
proc surveyselect data=chp09 out=train_test_split seed=42 samprate=0.8 outall;
run;

data train;
    set train_test_split;
    if Selected then output;
run;

data test;
    set train_test_split;
    if not Selected then output;
run;

/* Train the logistic regression model */
proc logistic data=train;
    model DECES(event='1') = SEXE ADM_HIS ACC FUME AGE SYS SERV SOIN CONS;
    output out=train_pred p=pred;
run;

/* Define the input parameters for prediction */
data input_params;
    SEXE = 0;
    ADM_HIS = 0;
    ACC = 0;
    FUME = 0;
    AGE = 40;
    SYS = 0;
    SERV = 0;
    SOIN = 0;
    CONS = 0;
run;

/* Predict the probability of death */
proc logistic inmodel=train;
    score data=input_params out=prediction;
run;

/* Display the predicted probability */
proc print data=prediction;
run;

/* Predict probabilities on the test set */
proc logistic inmodel=train;
    score data=test out=test_predictions;
run;

/* Calculate the AUC-ROC */
proc logistic data=test_predictions;
    model DECES(event='1') = p_1;
    roc;
run;
