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
#define BB_UPPER(bb, intv) (bb[(intv * BB_VALUES)])
#define BB_MAIN(bb, intv)  (bb[(intv * BB_VALUES) + 1])
#define BB_LOWER(bb, intv) (bb[(intv * BB_VALUES) + 2])

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
input int       BB_VALUES       = 3;
input int       BB_SHIFT        = 0;

/* Shared/global variable definitions. */
double bb[];

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
    /* Resize bollinger data array with required size. */
    ArrayResize(bb, NUM_INTERVALS * BB_VALUES);

    /* Collect data from all the intervals. */
    for (int i = 0; (i < NUM_INTERVALS); i++)
    {
        BB_UPPER(bb, i) = iBands(NULL, inervals[i], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_UPPER, 0);
        BB_MAIN(bb, i)  = iBands(NULL, inervals[i], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_MAIN, 0);
        BB_LOWER(bb, i) = iBands(NULL, inervals[i], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_LOWER, 0);
    }
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
        indicatorInfo += ((Close[0] > BB_UPPER(bb, i)) ? "*" : " ") + DoubleToStr(BB_UPPER(bb, i), 2);
        indicatorInfo += (((Close[0] <= BB_UPPER(bb, i)) && (Close[0] > BB_MAIN(bb, i))) ? " * " : "   ") + DoubleToStr(BB_MAIN(bb, i), 2);
        indicatorInfo += (((Close[0] <= BB_MAIN(bb, i)) && (Close[0] > BB_LOWER(bb, i))) ? " * " : "   ") + DoubleToStr(BB_LOWER(bb, i), 2);
        indicatorInfo += ((Close[0] < BB_LOWER(bb, i)) ? " *" : "  ");

        /* Terminate this line. */
        indicatorInfo += "\n";
    }

    /* Print the collected data. */
    Comment(indicatorInfo);

}
