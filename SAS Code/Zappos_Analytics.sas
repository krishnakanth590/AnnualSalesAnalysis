* Creating a library to store SAS Datasets ;
LIBNAME Zappos 'C:\sas\myfolders\Zappos\' ;

* Defining input file name and location ;
FILENAME Inp_Data 'C:\Analytics_Challenge_Data_2.csv' ;

* Importing the CSV file as it is ;
DATA Zappos.Dataset_Crude;
INFILE Inp_Data DELIMITER=',' FIRSTOBS = 2 MISSOVER DSD;
INFORMAT day mmddyy10. platform $15.;
INPUT day $ site $ new_customer platform $ visits distinct_sessions orders gross_sales bounces 
		add_to_cart product_page_views search_page_views;
RUN; 

* Creating metrics: coonversion_rate, bounce_rate, add_to_cart_rate ;
DATA Zappos.Dataset_Intermediate;
	SET Zappos.Dataset_Crude;
	Month = MONTH(day); * Extracting month from date ;
	day_of_week = WEEKDAY(day); * Extracting day of the week from from date ;
	conversion_rate = orders / visits; 
	bounce_rate = bounces / visits;
	add_to_cart_rate = add_to_cart / visits;
	* Condition to eliminate observations with missing values ; 
 	WHERE day IS NOT NULL
		AND site IS NOT NULL
		AND new_customer ^= .
		AND new_customer ^= .
		AND platform IS NOT NULL
		AND visits ^= .
		AND distinct_sessions ^= .
		AND orders ^= .
		AND gross_sales ^= .
		AND bounces ^= .
		AND add_to_cart ^= .
		AND product_page_views ^= .
		AND search_page_views ^= .;
		
RUN; 

* Eliminating records with null values for metrics calculated above;
DATA Zappos.Dataset_NomissingValues;
	SET Zappos.Dataset_Intermediate;
	WHERE search_page_views ^= .
		AND conversion_rate ^= .
		AND bounce_rate ^= .
		AND add_to_cart_rate ^= .;
	LABEL 
		day = 'Day'
		site = 'Site'
		new_customer = 'New_Customer?'
		platform = 'Platform'
		visits = 'Visits'
		distinct_sessions = 'Distinct Sessions'
		orders = 'Orders'
		gross_sales = 'Gross Sales'
		bounces = 'Bounces'
		add_to_cart = 'Add to cart'
		product_page_views = 'Prodcut page views'
		search_page_views = 'Search page views'
		conversion_rate = 'Conversion rate'
		bounce_rate = 'Bounce rate'
		add_to_cart_rate = 'Add to cart rate';
RUN;

* Creating SAS formats to format month name, day of week and new customer ;
PROC FORMAT;
	VALUE MONTH_FMT 1 = 'January'
					2 = 'February'
					3 = 'March'
					4 = 'April'
					5 = 'May'
					6 = 'June'
					7 = 'July'
					8 = 'August'
					9 = 'September'
					10 = 'October'
					11 = 'November'
					12 = 'December';
	VALUE WEEK_FMT 1 = 'Sunday'
				   2 = 'Monday'
				   3 = 'Tuesday'
				   4 = 'Wednesday'
				   5 = 'Thursday'
				   6 = 'Friday'
				   7 = 'Saturday';
	VALUE CUST_FMT 1 = 'Yes'
				   0 = 'No';
	VALUE WEEK_FMT_SHORT 1 = 'S'
				   2 = 'M'
				   3 = 'T'
				   4 = 'W'
				   5 = 'TH'
				   6 = 'F'
				   7 = 'SA';
RUN;

* Creating final data set for analysis ;
DATA Zappos.Dataset_Final;
	SET Zappos.Dataset_NoMissingValues;
	* Applying formats ;
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;


* Frequency Table ;
PROC FREQ DATA = Zappos.Dataset_Final ;
	TITLE "Frequency distribution table";
	TABLES site platform month day_of_week / NOCUM ;
RUN;


* Correlation matrix ;
PROC CORR DATA = Zappos.Dataset_Final;
	TITLE "Correlation matrix";
	VAR visits orders gross_sales distinct_sessions bounces 
		add_to_cart product_page_views search_page_views conversion_rate bounce_rate add_to_cart_rate;
RUN;


* Bar graphs ;
* Distribution of Orders by month (Percentage of orders);
PATTERN1 COLOR=VIBG VALUE = S;
PATTERN2 COLOR=STRO VALUE = S;
axis1 label=(a=90 f="Arial/Bold" "Total number of orders") minor=(n=5);
axis2 label= (f="Arial/Bold" "Month of the year");  
axis3 label= (f="Arial/Bold" "New Customer?");
PROC GCHART DATA = Zappos.Dataset_Final;
	TITLE "Distribution of Orders by Month (Percentage of orders)";
	VBAR Month / SUBGROUP = new_customer 
	SUMVAR = Orders 
	TYPE = SUM DISCRETE 
	OUTSIDE = PERCENTSUM
	INSIDE = PERCENTSUM
	raxis=axis1
	maxis =axis2
	gaxis = axis3;
	FORMAT new_customer CUST_FMT.;
RUN;

* Distribution of Orders by platform  ;
PATTERN1 COLOR=VIBG VALUE = S;
PATTERN2 COLOR=STRO VALUE = S;
axis1 label=( f="Arial/Bold" "Total number of orders") minor=(n=5);
axis2 label= (a=90 f="Arial/Bold" "Platform");  
PROC GCHART DATA = Zappos.Dataset_Final;
	TITLE "Distribution of Orders by Platform";
	HBAR  Platform /
	SUBGROUP = new_customer 
	SUMVAR = orders
	OUTSIDE = SUM PERCENTSUM
	SUMLABEL = 'Orders'
	PCTSUMLABEL = 'Percent'
	raxis=axis1
	maxis =axis2;
	FORMAT new_customer CUST_FMT.;
RUN;

* Distribution of Orders by site  ;
PATTERN1 COLOR=VIBG VALUE = S;
PATTERN2 COLOR=STRO VALUE = S;
axis1 label=(a=90 f="Arial/Bold" "Total number of orders") minor=(n=5);
axis2 label= (f="Arial/Bold" "Platform");
axis3 label= (f="Arial/Bold" "New Customer?"); 
PROC GCHART DATA = Zappos.Dataset_Final;
	TITLE "Distribution of Orders by Site";
	VBAR  site /
	SUBGROUP = new_customer 
	SUMVAR = orders
	OUTSIDE = PERCENTSUM
	raxis=axis1
	maxis =axis2
	gaxis = axis3;
	FORMAT new_customer CUST_FMT.;
RUN;

* Distribution of Orders by day_of_week  ;
PATTERN1 COLOR=VIBG VALUE = S;
PATTERN2 COLOR=STRO VALUE = S;
axis1 label=(a=90 f="Arial/Bold" "Total number of orders") minor=(n=5);
axis2 label= (f="Arial/Bold" "Day of the week");  
PROC GCHART DATA = Zappos.Dataset_Final;
	TITLE "Distribution of Orders by day_of_week";
	VBAR  day_of_week / DISCRETE
	SUBGROUP = new_customer 
	SUMVAR = orders
	TYPE = SUM
	OUTSIDE = PERCENTSUM
	INSIDE = SUM
	raxis=axis1
	maxis =axis2;
	FORMAT new_customer CUST_FMT.;
RUN;

* Distribution of Orders by day_of_week, group by month ;
PATTERN1 COLOR=VIBG VALUE = S;
PATTERN2 COLOR=STRO VALUE = S;
axis1 label=(a=90 f="Arial/Bold" "Total number of orders") minor=(n=5);
axis2 label= (f="Arial/Bold" "Day of the week");  
axis2 label= (f="Arial/Bold" "Day of the week");  
PROC GCHART DATA = Zappos.Dataset_Final;
	TITLE "Distribution of Orders by day_of_week";
	VBAR  day_of_week / GROUP = month DISCRETE
	SUBGROUP = new_customer 
	SUMVAR = orders
	TYPE = SUM
	OUTSIDE = PERCENTSUM
	INSIDE = SUM
	raxis=axis1
	maxis =axis2;
	FORMAT new_customer CUST_FMT. day_of_week Week_fmt_short.;
RUN;

* Scatter plots ;

SYMBOL VALUE = DOT COLOR = STRO;
PROC GPLOT DATA = Zappos.Dataset_Final;
	TITLE "Orders Vs Visits";
	PLOT orders*visits;
RUN;

SYMBOL VALUE = DOT COLOR = RED;
PROC GPLOT DATA = Zappos.Dataset_Final;
	TITLE "Orders Vs Distinct Sessions";
	PLOT orders*distinct_sessions;
RUN;

SYMBOL VALUE = DOT COLOR = VIBG;
PROC GPLOT DATA = Zappos.Dataset_Final;
	TITLE "Orders Vs Bounces";
	PLOT orders*bounces;
RUN;

SYMBOL VALUE = DOT COLOR = OliveDrab;
PROC GPLOT DATA = Zappos.Dataset_Final;
	TITLE "Orders Vs Add to cart";
	PLOT orders*add_to_cart;
RUN;

SYMBOL VALUE = DOT COLOR = DarkGoldenrod;
PROC GPLOT DATA = Zappos.Dataset_Final;
	TITLE "Orders Vs Product page views";
	PLOT orders*product_page_views;
RUN;

SYMBOL VALUE = DOT COLOR = DarkViolet;
PROC GPLOT DATA = Zappos.Dataset_Final;
	TITLE "Orders Vs Search Page Views";
	PLOT orders*search_page_views;
RUN;

* Anova ; 
PROC ANOVA DATA = Zappos.Dataset_Final;
	CLASS site;
	MODEL orders = site;
	MEANS site / snk;
RUN;
QUIT;

PROC ANOVA DATA = Zappos.Dataset_Final;
	CLASS platform;
	MODEL orders = platform;
	MEANS platform / snk;
RUN;
QUIT;


PROC ANOVA DATA = Zappos.Dataset_Final;
	CLASS month;
	MODEL orders = month;
	MEANS month / snk;
RUN;
QUIT;


PROC ANOVA DATA = Zappos.Dataset_Final;
	CLASS day_of_week;
	MODEL orders = day_of_week;
	MEANS day_of_week / snk;
RUN;
QUIT;

* Creating dataset with dummy variables ;
DATA Zappos.Dataset_final_dummies;
	SET Zappos.Dataset_final;
	* Dummy variables for site ;
	IF site = 'Acme' THEN 
	DO 
		site_botly = 0 ;
		site_pinnacle = 0 ;
		site_sortly = 0 ;
		site_tabular = 0 ;
		site_widgetry = 0;
	END;
	ELSE IF site = 'Botly' THEN 
	DO 
		site_botly = 1 ;
		site_pinnacle = 0 ;
		site_sortly = 0 ;
		site_tabular = 0 ;
		site_widgetry = 0;
	END;
	ELSE IF site = 'Pinnacle' THEN 
	DO 
		site_botly = 0 ;
		site_pinnacle = 1 ;
		site_sortly = 0 ;
		site_tabular = 0 ;
		site_widgetry = 0;
	END;
	ELSE IF site = 'Sortly' THEN 
	DO 
		site_botly = 0 ;
		site_pinnacle = 0 ;
		site_sortly = 1 ;
		site_tabular = 0 ;
		site_widgetry = 0;
	END;
	ELSE IF site = 'Tabular' THEN 
	DO 
		site_botly = 0 ;
		site_pinnacle = 0 ;
		site_sortly = 0 ;
		site_tabular = 1 ;
		site_widgetry = 0;
	END;
	ELSE IF site = 'Widgetry' THEN 
	DO 
		site_botly = 0 ;
		site_pinnacle = 0 ;
		site_sortly = 0 ;
		site_tabular = 0 ;
		site_widgetry = 1;
	END;
	* Dummy variables for Platform ;
	IF platform = 'Android' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'BlackBerry' THEN 
	DO 
		platform_blackberry = 1 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'ChromeOS' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 1;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'iOS' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 1;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'iPad' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 1;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'iPhone' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 1;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'Linux' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 1;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'Macintosh' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 1;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'MacOSX' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 1;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'Other' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 1;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'Unknown' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 1;
		platform_windows = 0;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'Windows' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 1;
		platform_windowsphone = 0;
	END;
	ELSE IF platform = 'WindowsPhone' THEN 
	DO 
		platform_blackberry = 0 ;
		platform_chromeos = 0;
		platform_ios = 0;
		platform_ipad = 0;
		platform_iphone = 0;
		platform_linux = 0;
		platform_macintosh = 0;
		platform_macosx = 0;
		platform_other = 0;
		platform_unknown = 0;
		platform_windows = 0;
		platform_windowsphone = 1;
	END;
	* Dummy variables for Month ;
	IF month = 1 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 2 THEN 
	DO 
		month_february = 1;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 3 THEN 
	DO 
		month_february = 0;
		month_march = 1;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 4 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 1;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 5 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 1;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 6 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 1;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 7 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 1;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 8 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 1;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 9 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 1;
		month_october= 0;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 10 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 1;
		month_november= 0;
		month_december= 0;
	END;
	IF month = 11 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 1;
		month_december= 0;
	END;
	IF month = 12 THEN 
	DO 
		month_february = 0;
		month_march = 0;
		month_april = 0;
		month_may= 0;
		month_june= 0;
		month_july= 0;
		month_august= 0;
		month_september= 0;
		month_october= 0;
		month_november= 0;
		month_december= 1;
	END;
RUN;


* Regression ;
SYMBOL VALUE = DOT COLOR = RED;
PROC REG DATA = Zappos.Dataset_final_dummies OUTEST = Zappos.Estimates PLOTS(MAXPOINTS = 11000);
	Predicted_Sales: MODEL gross_sales = new_customer visits bounce_rate add_to_cart_rate
		site_botly 
		site_pinnacle  
		site_sortly  
		site_tabular  
		site_widgetry
		platform_blackberry
		platform_ios 
		platform_ipad
		platform_iphone 
		platform_linux 
		platform_chromeos 
		platform_macintosh 
		platform_macosx 
		platform_other
		platform_unknown 
		platform_windows
		platform_windowsphone 
		month_february 
		month_march 
		month_april 
		month_may
		month_june
		month_july
		month_august
		month_september
		month_october
		month_november
		month_december / SELECTION = stepwise VIF;
		PLOT RESIDUAL.*PREDICTED.;
RUN;
QUIT;

* Scoring the model ;
PROC SCORE DATA = Zappos.Dataset_final_dummies SCORE = Zappos.Estimates TYPE = PARMS OUT = Zappos.Scored_Data;
VAR new_customer visits bounce_rate add_to_cart_rate
		site_botly 
		site_pinnacle  
		site_sortly  
		site_tabular  
		platform_blackberry
		platform_ios 
		platform_ipad
		platform_linux 
		platform_chromeos 
		platform_macintosh 
		platform_macosx 
		platform_unknown 
		platform_windows
		platform_windowsphone 
		month_june
		month_july
		month_august
		month_september
		month_november
		month_december;
ID gross_sales;
RUN;
QUIT;



SYMBOL VALUE = DOT COLOR = VIO;
PROC GPLOT DATA = Zappos.Scored_Data;
	PLOT gross_sales*predicted_sales;
RUN;


* Residual dataset ;
DATA Zappos.Residuals;
	SET Zappos.scored_data;
	residual = gross_sales-Predicted_sales;
RUN;

PROC UNIVARIATE DATA = Zappos.Residuals;
	VAR residual;
	HISTOGRAM residual / NORMAL;
RUN;



/************************************** Junk Code *************************************************/


* Sorting data by day, site and platform ;
PROC SORT DATA = Zappos.Dataset_NoMissingValues OUT = Zappos.Dataset_Sorted_Day_Site_Platform;
	BY day site platform;
RUN;
QUIT;



* Splitting data set by site ;
DATA Zappos.Dataset_Final_Acme;
	SET Zappos.Dataset_NoMissingValues;
	WHERE site = 'Acme';
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;
DATA Zappos.Dataset_Final_Botly;
	SET Zappos.Dataset_NoMissingValues;
	WHERE site = 'Botly';
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;
DATA Zappos.Dataset_Final_Pinnacle;
	SET Zappos.Dataset_NoMissingValues;
	WHERE site = 'Pinnacle';
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;
DATA Zappos.Dataset_Final_Sortly;
	SET Zappos.Dataset_NoMissingValues;
	WHERE site = 'Sortly';
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;
DATA Zappos.Dataset_Final_Tabular;
	SET Zappos.Dataset_NoMissingValues;
	WHERE site = 'Tabular';
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;
DATA Zappos.Dataset_Final_Widgetry;
	SET Zappos.Dataset_NoMissingValues;
	WHERE site = 'Widgetry';
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;
RUN;

DATA Zappos.Dataset_Final_Site;
	SET Zappos.Dataset_Sorted_Site_Platform;
	FORMAT day mmddyy10. Month MONTH_FMT. day_of_week WEEK_FMT.;		
RUN;

* Univariate to find out outliers ;
PROC UNIVARIATE DATA = Zappos.Dataset_Final;
	TITLE "Finding outliers";
	VAR new_customer visits distinct_sessions orders gross_sales bounces 
		add_to_cart product_page_views search_page_views;
	HISTOGRAM new_customer visits distinct_sessions orders gross_sales bounces 
		add_to_cart product_page_views search_page_views / NORMAL;
RUN;


PROC FREQ DATA = Zappos.Dataset_Final;
	TABLES site*platform / chisq;
RUN;

PROC FREQ DATA = Zappos.Dataset_Final;
	TABLES site*month / chisq;
RUN;

PROC FREQ DATA = Zappos.Dataset_Final;
	TABLES month*platform/ chisq;
RUN;



* Sorting the dataset by Site name and saving in different dataset ;
PROC SORT DATA = Zappos.Dataset_Final OUT = Zappos.Dataset_Final_Sort_Site;
	BY site;
RUN;

PROC MEANS DATA = Zappos.Dataset_Final_Sort_Site MEAN MIN MAX SUM;
	VAR orders;
	BY site;
RUN; 
* Sorting the dataset by day_of_week and saving in different dataset ;
PROC SORT DATA = Zappos.Dataset_Final OUT = Zappos.Dataset_Final_Sort_day_of_week;
	BY day_of_week;
RUN;
PROC MEANS DATA = Zappos.Dataset_Final_Sort_day_of_week MEAN MIN MAX SUM;
	VAR orders;
	BY day_of_week;
RUN; 

* Distribution of Orders by month (Number of orders);
PATTERN1 COLOR=VIBG VALUE = S;
PATTERN2 COLOR=STRO VALUE = S;
axis1 label=(a=90 f="Arial/Bold" "Total number of orders") minor=(n=5);
axis2 label= (f="Arial/Bold" "Month of the year");  
axis3 label= (f="Arial/Bold" "New Customer?");
PROC GCHART DATA = Zappos.Dataset_Final;
	TITLE "Distribution of Orders by Month (Number of orders)";
	VBAR Month / SUBGROUP = new_customer 
	SUMVAR = Orders 
	TYPE = SUM DISCRETE 
	OUTSIDE = SUM
	INSIDE = SUM
	raxis=axis1
	gaxis =axis2
	maxis =axis3;
	FORMAT new_customer CUST_FMT.;
RUN;

* Pie Charts ;
* Creating a lengent for different sites ;
legend1 label = none
		position = (left middle)
		offset = (4,)
		across = 1
		value = (color = black)
		shape = bar(6,2);
PROC GCHART DATA = Zappos.Dataset_final;
	PIE site / SUMVAR = orders TYPE = SUM other = 0 value = none percent = inside levels = all NOHEADING
	legend = legend1;
RUN;
* Platform ;
legend1 label = none
		position = (left middle)
		offset = (4,)
		across = 1
		value = (color = black)
		shape = bar(6,2);
PROC GCHART DATA = Zappos.Dataset_final;
	PIE platform / SUMVAR = orders TYPE = SUM other = 0 value = none percent = inside levels = all NOHEADING
	legend = legend1;
RUN;
* Month ;
legend1 label = none
		position = (left middle)
		offset = (4,)
		across = 1
		value = (color = black)
		shape = bar(6,2);
PROC GCHART DATA = Zappos.Dataset_final;
	PIE month / SUMVAR = orders TYPE = SUM other = 0 value = none percent = inside levels = all NOHEADING
	legend = legend1;
RUN;
* Residual dataset ;
DATA Zappos.Residuals;
	SET Zappos.scored_data;
	residual = gross_sales-Predicted_sales;
RUN;

PROC MEANS Data = Zappos.Residuals SUM;
	VAR residual;
RUN;

* Residual graph ;
SYMBOL VALUE = DOT COLOR = BLUE;
PROC GPLOT DATA = Zappos.Residuals;
	PLOT residual * gross_sales;
RUN;

SYMBOL VALUE = DOT COLOR = BLUE;
PROC GPLOT DATA = Zappos.scored_data;
	PLOT gross_sales*Predicted_sales;
RUN;

PROC CORR DATA = Zappos.scored_data;
	VAR gross_sales Predicted_sales;
RUN;

PROC UNIVARIATE DATA = Zappos.scored_data;
	VAR Predicted_sales gross_sales;
	HISTOGRAM Predicted_sales gross_sales / NORMAL;
RUN;

PROC PRINT DATA = Zappos.Dataset_final_dummies;
	VAR platform platform_blackberry
		platform_ios 
		platform_ipad
		platform_iphone 
		platform_linux 
		platform_chromeos 
		platform_macintosh 
		platform_macosx 
		platform_other
		platform_unknown 
		platform_windows
		platform_windowsphone;
	WHERE platform = 'WindowsPhone';
RUN;


* Score for all variables ;
PROC SCORE DATA = Zappos.Dataset_final_dummies SCORE = Zappos.Estimates TYPE = PARMS OUT = Zappos.Scored_Data;
VAR new_customer visits distinct_sessions bounces add_to_cart product_page_views search_page_views
		platform_ios 
		platform_ipad
		platform_linux 
		platform_macintosh 
		platform_macosx 
		platform_unknown 
		platform_windows
		site_botly 
		site_pinnacle  
		site_sortly  
		site_tabular  
		site_widgetry;
RUN;
QUIT;


* Including all the variables in the model ;
SYMBOL VALUE = DOT COLOR = BLUE;
PROC REG DATA = Zappos.Dataset_final_dummies;
		Predicted_Orders: MODEL orders = new_customer visits distinct_sessions bounces add_to_cart product_page_views search_page_views
		platform_blackberry
		platform_ios 
		platform_ipad
		platform_iphone 
		platform_linux 
		platform_chromeos 
		platform_macintosh 
		platform_macosx 
		platform_other
		platform_unknown 
		platform_windows
		platform_windowsphone 
		month_february 
		month_march 
		month_april 
		month_may
		month_june
		month_july
		month_august
		month_september
		month_october
		month_november
		month_december / SELECTION = STEPWISE VIF;
		PLOT RESIDUAL.*PREDICTED.;
RUN;
QUIT;

DATA Zappos.Dataset_test;
	SET Zappos.Dataset_final_dummies;
	WHERE month ^= 12 AND month ^= 11;
RUN;

DATA Zappos.Dataset_test2;
	SET Zappos.Dataset_final_dummies;
	WHERE site = 'Acme';
RUN;
