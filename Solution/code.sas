/* Import a file kobe.xlsx */
%web_drop_table(WORK.IMPORT);
FILENAME MyFile '/folders/myfolders/Kobe.xlsx';

PROC IMPORT DATAFILE=MyFile
	DBMS=XLSX
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.IMPORT; RUN;

%web_open_table(WORK.IMPORT);


data Kobe1;
set WORK.IMPORT;
run;
/*
proc print data=Kobe1(obs=15);
run;
*/

PROC SORT DATA=Kobe1;
   by shot_zone_range;
run;

/*Summary of the Variables */
proc means data=Kobe1 chartype mean mode std min max n vardef=df;
*	var lat loc_x loc_y lon minutes_remaining period playoffs seconds_remaining 
		shot_distance shot_made_flag game_date attendance arena_temp avgnoisedb;
run;


/* Frequency of getting output */
proc freq data=Kobe1;
table shot_made_flag;
run;


/* Count missing values for numeric variables */
DATA Kobe2; 
  set Kobe1;
  if missing(shot_made_flag) then delete;
run;
proc print data=Kobe2(obs=10);
run;

/*Bar Chart : Target Variable Visualization */

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=Kobe1;
	title height=14pt "Target Variable Class Distribution";
	vbar shot_made_flag / fillattrs=(color=CX5f9ae7) datalabel stat=percent;
	yaxis grid;
run;


ods graphics / reset;
title;


/*Bar graph of shot_zone_area */
title'Accuracy of the shot by shot_zone_area';

proc sgplot data=Kobe1;
	vbar shot_zone_area /;
	yaxis grid;
run;


/*Summary of the Variables */
proc means data=Kobe1 chartype mean std min max n vardef=df;
	var shot_distance shot_made_flag;
	class shot_type;
run;


/*** Analyze categorical variables ***/
title "Frequency for Categorical Variables";

proc freq data=Kobe1;
	tables action_type combined_shot_type shot_type shot_zone_area shot_zone_basic 
		shot_zone_range / plots=(freqplot);
run;

/*** Analyze numeric variables ***/
title "Descriptive Statistics for Numeric Variables";

proc means data=Kobe1 n nmiss min mean median max std;
	var shot_made_flag;
run;


/* Define Pie template  for shot_zone_range*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "Shot Zone Range Distribution In %" / textattrs=(size=14);
		layout region;
		piechart category=shot_zone_range / stat=pct;
		endlayout;
		endgraph;
	end;
run;



proc sgrender template=SASStudio.Pie data=Kobe1;
run;




/*Frequency of Shots by Shot_Zone_Area */
proc sgplot data=Kobe1;
	title height=14pt "Frequency of Shots by Shot_Zone_Area";
	vbar shot_zone_area / group=shot_made_flag groupdisplay=cluster datalabel;
	yaxis grid label="Shots";
run;


/*Frequency of shots by shot_zone_basic */
proc sgplot data=Kobe1;
	title height=14pt "Frequency of shots by shot_zone_basic";
	vbar shot_zone_basic / group=shot_made_flag groupdisplay=cluster datalabel;
	yaxis grid label="Shots";
	refline 6253 / axis=y lineattrs=(thickness=2 color=green) 
		label="Highest Accuracy" labelattrs=(color=green);
run;

	
/* Combined Shot type vs Shot made by flag */ 
proc sgplot data=Kobe1;
	hbar combined_shot_type / group=shot_made_flag groupdisplay=cluster;
	xaxis grid;
run;
	
/*Bar graph to show the total shots of particular action_type*/ 
proc sort data=Kobe1 out=BarChartTaskData_action_type;
	by shot_made_flag;
run;

proc sgplot data=BarChartTaskData_action_type;
	by shot_made_flag;
	hbar action_type / group=shot_made_flag groupdisplay=cluster datalabel;
	xaxis min=100 grid;
run;

proc datasets library=WORK noprint;
	delete BarChartTaskData_action_type;
	run;
	
		
/*Variable Selection using LASSO method  */
proc glmselect data=kobe1;
class combined_shot_type action_type shot_type shot_zone_area shot_zone_basic 
		period playoffs shot_zone_range season opponent;
model shot_made_flag = combined_shot_type action_type shot_type arena_temp attendance
		shot_zone_area shot_zone_basic period shot_zone_range season avgnoisedb game_date lat lon 	playoffs	
		loc_y loc_x  minutes_remaining seconds_remaining shot_distance shot_id / selection=lasso(stop=none);
run;

/*Outlier Identification */
title 'Outlier Identification for continuous-valued variable';
proc univariate data=kobe1 robustscale plot;
var      arena_temp attendance  period   avgnoisedb game_date lat lon 	playoffs	
		loc_y loc_x  minutes_remaining seconds_remaining shot_distance shot_id;
run; 
 
	
/*Correlation Analysis for Feature Selection: Select the variable which has significant value greater then 0.05  */ 
title 'Correlation between the variables';
proc corr data=Kobe1 pearson nomiss nosimple rank 
		plots=matrix(histogram);
	var loc_x loc_y minutes_remaining period seconds_remaining
		shot_distance;
	with shot_made_flag;
run;

/*Multicollinearity*/
proc reg data=Kobe1;
model shot_made_flag = period  lon loc_y loc_x  minutes_remaining seconds_remaining shot_distance / tol vif COLLIN; /*vif = variance inflation factor and tol= tolorance */
run;


/* Lat and Lon scatter plot visualization  */
title 'lat and lon scatter plot and outlier detection';
proc sgplot data=Kobe1;
	scatter x=lat y=lon /;
	xaxis grid;
	yaxis grid;
run;


/* loc_x and loc_y scatter plot visualization  */
title 'loc_x and loc_y scatter plot and outlier detection';
proc sgplot data=Kobe1;
	scatter x=loc_x y=loc_y /;
	xaxis grid;
	yaxis grid;
run;


/* loc_x and loc_y scatter plot visualization by shot_zone_area  */
proc sgplot data=Kobe1;
	scatter x=loc_x y=loc_y / group=shot_zone_area;
	xaxis grid;
	yaxis grid;
run;


/*shots attempted by shot distance */
title 'shots attempted by shot distance';
proc sort data=Kobe1 out=HistogramTaskData_shot_made_flag;
	by shot_made_flag;
run;

proc sgplot data=HistogramTaskData_shot_made_flag;
	by shot_made_flag;
	title height=14pt "shots by shot_distance";
	histogram shot_distance / scale=count nbins=13 fillattrs=(color=CX4b5ab8) 
		weight=shot_made_flag;
	xaxis max=80;
	yaxis max=4000 grid;
run;

proc datasets library=WORK noprint;
	delete HistogramTaskData_shot_made_flag;
	run;


/*Accuracy by seconds_remaining */
title 'Accuracy by seconds_remaining';
proc sgplot data=Kobe1;
	title height=14pt "Accuracy by seconds_remaining";
	vbar seconds_remaining / group=shot_made_flag groupdisplay=stack datalabel;
	yaxis grid label="Accuracy";
run;



/* Import 2nd File */
title 'Import test file';

FILENAME MyFile2 '/folders/myfolders/project2Pred.xlsx';

PROC IMPORT DATAFILE=MyFile2
	DBMS=XLSX
	OUT=Kobe3;
	GETNAMES=YES;
RUN;


PROC CONTENTS DATA=Kobe3 varnum; RUN;

proc print data=Kobe3(obs=10);
run;


/* Change the data type of the variable shot_made_flag from char to num */
title 'Change the data type of the target variable from char to num';
data Kobe4;
set Kobe3;
shot_made_flag_new = input(shot_made_flag, 8.);
drop shot_made_flag;
rename shot_made_flag_new = shot_made_flag;
run;

/* Checked the mean of the target variable and in project2pred.xlsx replace NA values by 0.5 for further prediction */
title 'Checked the stats of the test file';
proc means data= Kobe2 mean mode;
var shot_made_flag;
RUN;


/* Logistic Regression: shot_made_flag(event='1') because we are only intresting in knowing the probability of getting shots done or made*/
/* Load file project2pred in a file as Kobe3 to show the prediction of the variable*/
/*Model training and getting AUC value with the accuracy of 0.70 i,e 70% */
/* I am using file name Kobe as to train the model and project2pred for prediction.*/
title 'Training of the model';
proc logistic  data=Kobe1 plots=all;
	class combined_shot_type action_type shot_type shot_zone_area shot_zone_basic 
		period  shot_zone_range season / param=glm;
	model shot_made_flag(event='1')=combined_shot_type action_type shot_type 
		shot_zone_area shot_zone_basic period season shot_zone_range  
		loc_y loc_x  minutes_remaining seconds_remaining shot_distance / 
		link=logit selection=forward slentry=0.05 hierarchy=single technique=fisher;
	output out=work.Logistic_stats1 xbeta=xbeta predicted=pred / alpha=0.05;
	score data =Kobe1  out=MyPred fitstat;
run;
proc print data=MyPred(obs=10);
run;


/*Model fit to predict the value */
title 'Test the accuracy of the model';
proc logistic  data=Kobe1;
	class combined_shot_type action_type shot_type shot_zone_area shot_zone_basic 
		period  shot_zone_range season / param=glm;
	model shot_made_flag(event='1')=combined_shot_type action_type shot_type 
		shot_zone_area shot_zone_basic period season shot_zone_range  
		loc_y loc_x  minutes_remaining seconds_remaining shot_distance / 
		link=logit selection=forward slentry=0.05 hierarchy=single technique=fisher;
	output out=work.Logistic_stats1 xbeta=xbeta predicted=pred / alpha=0.05;
	score data =Kobe4  out=MyPred_test;
run;

/* Show the result with shot_id and shot_made_flag */
data pridicted_value;
set MyPred_test;
drop  combined_shot_type  action_type  shot_type shot_zone_area shot_zone_basic period playoffs shot_zone_range  lat lon
		loc_y loc_x   minutes_remaining seconds_remaining shot_distance shot_made_flag rannum game_event_id game_id
		season team_id team_name game_date matchup opponent attendance arena_temp avgnoisedb F_shot_made_flag P_0;
label F_shot_made_flag = 'shot_made_flag'  P_0= 'Actual_Predicted_value';
run;
proc print data=pridicted_value(obs=50) label;
run;


/* Mis-Classification Chart or Confusion Matrix */
proc freq data=MyPred; 
tables F_shot_made_flag*I_shot_made_flag; 
run; 


 
 
 
 


 
 
 
 
 
 
 
 
