//+------------------------------------------------------------------+
//|                                                       Hybrid.mq4 |
//|                                     Copyright 2018, Usama Masood |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Usama Masood"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

/* Number of intervals. */
#define NUM_INTERVALS      9

/* Bollinger band definitions. */
#define BB_UPPER(intv)  (bb[(intv * BB_VALUES)])
#define BB_MAIN(intv)   (bb[(intv * BB_VALUES) + 1])
#define BB_LOWER(intv)  (bb[(intv * BB_VALUES) + 2])
#define BB_VALUES       3

/* Stochastic definitions. */
#define ST_VALUES       3
#define ST_MAIN(intv)   (st[(intv * ST_VALUES)])
#define ST_SIGNAL(intv) (st[(intv * ST_VALUES) + 1])
#define ST_DIR(intv)    (st[(intv * ST_VALUES) + 2])

/* Interval definitions. */
int inervals[NUM_INTERVALS] =
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

/* Interval string definitions. */
string inervalStrings[NUM_INTERVALS] =
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

/* Input configurations. */
input double    LOT_SIZE        = 0.1;
input int       BB_PERIOD       = 20;
input int       BB_DEVIATION    = 2;
input int       BB_SHIFT        = 0;
input int       ST_K            = 5;
input int       ST_D            = 3;
input int       ST_S            = 3;
input int       ST_UP           = 70;
input int       ST_DOWN         = 30;

/* Shared/global variable definitions. */
double bb[];
double st[];

int lastDirection = 0;

/**
 * This will be called on EA initialization.
 */
int OnInit()
{
    /* Read indicator values. */
    readIndicators();
    printIndicators();

    /* Always return success. */
    return (INIT_SUCCEEDED);

}

/**
 * This will be called on EA de initialization.
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
    /* Read indicator values. */
    readIndicators();
    printIndicators();
}

/**
 * This will read various indicator values.
 */
void readIndicators()
{
    /* Resize data arrays with required size. */
    ArrayResize(bb, NUM_INTERVALS * BB_VALUES);
    ArrayResize(st, NUM_INTERVALS * ST_VALUES);

    /* Collect data from all the intervals. */
    for (int i = 0; (i < NUM_INTERVALS); i++)
    {
        /* Gather Bollinger information. */
        BB_UPPER(i)     = iBands(NULL, inervals[i], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_UPPER, 0);
        BB_MAIN(i)      = iBands(NULL, inervals[i], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_MAIN, 0);
        BB_LOWER(i)     = iBands(NULL, inervals[i], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_LOWER, 0);

        /* Gather stochastic data. */
        ST_MAIN(i)      = iStochastic(NULL, inervals[i], ST_K, ST_D, ST_S, MODE_SMA, 0, MODE_MAIN, 0);
        ST_SIGNAL(i)    = iStochastic(NULL, inervals[i], ST_K, ST_D, ST_S, MODE_SMA, 0, MODE_SIGNAL, 0);
        ST_DIR(i)       = getStocasticDirection(inervals[i]);
    }
}

/**
 * This function will return true if stochastic is rising otherwise false will
 * be returned.
 */
int getStocasticDirection(int interval)
{
    double stMainThis, stSignalThis;

    /* Get stochastic readings. */
    stMainThis = iStochastic(NULL, interval, ST_K, ST_D, ST_S, MODE_SMA, 0, MODE_MAIN, 0);
    stSignalThis = iStochastic(NULL, interval, ST_K, ST_D, ST_S, MODE_SMA, 0, MODE_SIGNAL, 0);

    /* Return stochastic direction. */
    return (stMainThis > stSignalThis);

}

/**
 * This will print various indicator values.
 */
void printIndicators()
{
    string indicatorInfo = "";

    /* Traverse through all the intervals. */
    for (int i = 0; (i < NUM_INTERVALS); i++)
    {
        /* Add interval string. */
        indicatorInfo += "[" + inervalStrings[i] + "] ";

        /* Add Bollinger for this interval. */
        indicatorInfo += ((Close[0] > BB_UPPER(i)) ? "*" : " ") + DoubleToStr(BB_UPPER(i), 2);
        indicatorInfo += (((Close[0] <= BB_UPPER(i)) && (Close[0] > BB_MAIN(i))) ? " * " : "   ") + DoubleToStr(BB_MAIN(i), 2);
        indicatorInfo += (((Close[0] <= BB_MAIN(i)) && (Close[0] > BB_LOWER(i))) ? " * " : "   ") + DoubleToStr(BB_LOWER(i), 2);
        indicatorInfo += ((Close[0] < BB_LOWER(i)) ? " *" : "  ");

        /* Add stochastic data. */
        indicatorInfo += ((ST_DIR(i) == 1) ? "U" : "D");

        /* Terminate this line. */
        indicatorInfo += "\n";
    }

    /* Print the collected data. */
    Comment(indicatorInfo);

}
