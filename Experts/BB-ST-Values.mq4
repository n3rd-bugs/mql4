//+------------------------------------------------------------------+
//|                                                 BB-ST-Values.mq4 |
//|                                     Copyright 2018, Usama Masood |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright                     "Copyright 2018, Usama Masood"
#property link                          "https://github.com/n3rd-bugs/mql4"
#property version                       "1.0"
#property strict

/* Definitions. */
#define NUM_INTERVALS                   9

/* Interval definitions. */
int intervals[NUM_INTERVALS] =
{
    PERIOD_M1,
    PERIOD_M5,
    PERIOD_M15,
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H4,
    PERIOD_D1,
    PERIOD_W1,
    PERIOD_MN1,
};

enum INTERVAL_INDEX
{
    M1 = 0,
    M5,
    M15,
    M30,
    H1,
    H4,
    D1,
    W1,
    MN1,
};

/* Interval string definitions. */
string intervalStrings[NUM_INTERVALS] =
{
    "1min",
    "5min",
    "15min",
    "30min",
    "1h",
    "4h",
    "1d",
    "1w",
    "1m",
};

/* BB configurations. */
input int                   BB_PERIOD           = 20;
input int                   BB_DEVIATION        = 2;
input int                   BB_SHIFT            = 0;
input ENUM_APPLIED_PRICE    BB_APPLIED_PRICE    = PRICE_CLOSE;

input int                   ST_K                = 5;
input int                   ST_D                = 3;
input int                   ST_S                = 3;
input int                   ST_UP               = 80;
input int                   ST_DOWN             = 20;
input ENUM_MA_METHOD        ST_METHOD           = MODE_SMA;
input int                   ST_APPLIED_PRICE    = 1;

/* Bollinger band definitions. */
#define BB_VALUES                       4
#define BB_UPPER(intv)                  (bb[(intv * BB_VALUES)])
#define BB_MAIN(intv)                   (bb[(intv * BB_VALUES) + 1])
#define BB_LOWER(intv)                  (bb[(intv * BB_VALUES) + 2])
#define BB_DIR(intv)                    (bb[(intv * BB_VALUES) + 3])
#define BB_UPPER_CALC(intv, shift)      (iBands(NULL, intervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, BB_APPLIED_PRICE, MODE_UPPER, shift))
#define BB_MAIN_CALC(intv, shift)       (iBands(NULL, intervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, BB_APPLIED_PRICE, MODE_MAIN, shift))
#define BB_LOWER_CALC(intv, shift)      (iBands(NULL, intervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, BB_APPLIED_PRICE, MODE_LOWER, shift))

/* Stochastic definitions. */
#define ST_VALUES                       3
#define ST_MAIN(intv)                   (st[(intv * ST_VALUES)])
#define ST_SIGNAL(intv)                 (st[(intv * ST_VALUES) + 1])
#define ST_DIR(intv)                    (st[(intv * ST_VALUES) + 2])
#define ST_MAIN_CALC(intv, shift)       (iStochastic(NULL, intervals[intv], ST_K, ST_D, ST_S, ST_METHOD, ST_APPLIED_PRICE, MODE_MAIN, shift))
#define ST_SIGNAL_CALC(intv, shift)     (iStochastic(NULL, intervals[intv], ST_K, ST_D, ST_S, ST_METHOD, ST_APPLIED_PRICE, MODE_SIGNAL, shift))

/* Shared/global variable definitions. */
double bb[];
double st[];
string comment;

/**
 * This will be called on EA initialization.
 */
int OnInit()
{
    /* Initialize indicators. */
    initializeIndicators();

    /* Initialize comment. */
    comment = "";

    /* Read indicator values. */
    readIndicators();
    printIndicators();

    /* Print the collected comment. */
    Comment(comment);

    /* Always return success. */
    return (INIT_SUCCEEDED);

}

/**
 * This will be called on EA deinitialization.
 */
void OnDeinit(const int reason)
{
    ;
}

/**
 * This will be called whenever price is updated.
 */
void OnTick()
{
    /* Verify that we have enough data on the chart. */
    if (Bars < 100)
    {
        Print("bars less than 100");
        return;
    }

    /* Initialize comment. */
    comment = "";

    /* Read indicator values. */
    readIndicators();
    printIndicators();

    /* Print the collected comment. */
    Comment(comment);
}

/**
 * This will initialize various indicators.
 */
void initializeIndicators()
{
    /* Resize data arrays with required size. */
    ArrayResize(bb, NUM_INTERVALS * BB_VALUES);
    ArrayResize(st, NUM_INTERVALS * ST_VALUES);
}

/**
 * This will read various indicator values.
 */
void readIndicators()
{
    /* Collect data from all the intervals. */
    for (int i = 0; (i < NUM_INTERVALS); i++)
    {
        /* Gather Bollinger information. */
        BB_UPPER(i)     = BB_UPPER_CALC(i, 0);
        BB_MAIN(i)      = BB_MAIN_CALC(i, 0);
        BB_LOWER(i)     = BB_LOWER_CALC(i, 0);
        BB_DIR(i)       = (BB_UPPER_CALC(i, 0) - BB_LOWER_CALC(i, 0)) - (BB_UPPER_CALC(i, 1) - BB_LOWER_CALC(i, 1));

        /* Gather stochastic data. */
        ST_MAIN(i)      = ST_MAIN_CALC(i, 0);
        ST_SIGNAL(i)    = ST_SIGNAL_CALC(i, 0);
        ST_DIR(i)       = (ST_MAIN(i) > ST_SIGNAL(i));
   }
}

/**
 * This will print various indicator values.
 */
void printIndicators()
{
    MqlDateTime time;
    double passed;
        
    /* Get current time. */
    TimeCurrent(time);
    
    /* Traverse through all the intervals. */
    for (int i = 0; (i < NUM_INTERVALS); i++)
    {
        /* Add interval string. */
        comment += "[" + intervalStrings[i] + "] ";

        /* Add Bollinger for this interval. */
        comment += (BB_DIR(i) == 0) ? " S " : ((BB_DIR(i) > 0) ? " E " : " C ");
        comment += ((Close[0] > BB_UPPER(i)) ? "*" : " ") + DoubleToStr(BB_UPPER(i), Digits);
        comment += (((Close[0] <= BB_UPPER(i)) && (Close[0] > BB_MAIN(i))) ? " * " : "   ") + DoubleToStr(BB_MAIN(i), Digits);
        comment += (((Close[0] <= BB_MAIN(i)) && (Close[0] > BB_LOWER(i))) ? " * " : "   ") + DoubleToStr(BB_LOWER(i), Digits);
        comment += ((Close[0] < BB_LOWER(i)) ? " *" : "  ");

        /* Add stochastic data. */
        comment += ((ST_DIR(i) == 1) ? "U " : "D ");
        
        /* Calculate the percentage of interval passed. */
        switch (i) 
        {
        case M1:
            passed = ((time.sec) * 100.0) / 60.0;
            break;
        case M5:
            passed = ((time.sec + ((time.min % 5) * 60.0)) * 100.0) / (60.0 * 5.0);
            break;
        case M15:
            passed = ((time.sec + ((time.min % 15) * 60.0)) * 100.0) / (60.0 * 15.0);
            break;
        case M30:
            passed = ((time.sec + ((time.min % 30) * 60.0)) * 100.0) / (60.0 * 30.0);
            break;
        case H1:
            passed = ((time.sec + (time.min * 60.0)) * 100.0) / (60.0 * 60.0);
            break;
        case H4:
            passed = ((time.sec + (time.min * 60.0) + ((time.hour % 4) * 60.0 * 60.0)) * 100.0) / (60.0 * 60.0 * 4);
            break;
        case D1:
            passed = ((time.sec + (time.min * 60.0) + (time.hour * 60.0 * 60.0)) * 100.0) / (60.0 * 60.0 * 24);
            break;
        case W1:
            passed = ((time.sec + (time.min * 60.0) + (time.hour * 60.0 * 60.0) + 
                      ((((time.day_of_week == 0) && (time.day_of_week == 6)) ? 5 : time.day_of_week - 1) * 60.0 * 60.0 * 24)) * 100.0) / 
                     (60.0 * 60.0 * 24 * 5);
            break;
        case MN1:
            passed = ((time.sec + (time.min * 60.0) + (time.hour * 60.0 * 60.0) + 
                      (month_work_days(time.day - 1, time.mon, time.year) * 60.0 * 60.0 * 24)) * 100.0) / 
                     (60.0 * 60.0 * 24 * month_work_days(month_days(time.mon, time.year), time.mon, time.year));            
            break;
        default:
            passed = 0;
            break;
        }
        
        /* Add the percentage of interval has passed. */
        comment += DoubleToStr(passed, 1);
        comment += "%";

        /* Terminate this line. */
        comment += "\n";
    }
}

/**
 * This will return if this is a leap year or not.
 */
bool is_leap(int year)
{
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

/**
 * This will return the number of days in a month.
 */
int month_days(int month, int year)
{
    static const int days[2][13] = {
        {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
        {0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    };
    
    /* Return the number of days in this month. */
    return (days[is_leap(year)][month]);

}

/**
 * This will return the number of working days passed till the given date.
 */
int month_work_days(int day, int month, int year)
{
    int work_days = 0;
    int i;
    MqlDateTime time;
    
    /* Traverse all the the days. */
    for (i = 1; i <= day; i ++)
    {
        /* Construct the date. */
        TimeToStruct(StrToTime(IntegerToString(year) + "." + 
                               IntegerToString(month) + "." + 
                               IntegerToString(i)), time);
        
        /* Test if this is a working day. */
        if ((time.day_of_week != 0) && (time.day_of_week != 6))
        {
            work_days ++;
        }
    }
    
    /* Retrun the number of working days. */
    return (work_days);

}
