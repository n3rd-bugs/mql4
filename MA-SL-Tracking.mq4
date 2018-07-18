//+------------------------------------------------------------------+
//|                                                optimal_close.mq4 |
//|                                     Copyright 2018, Usama Masood |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright                     "Copyright 2018, Usama Masood"
#property link                          "https://github.com/n3rd-bugs/mql4"
#property version                       "1.0"
#property strict

/* Definitions. */
#define NUM_INTERVALS                   9
#define MAGIC                           0x145211

/* Test definitions. */
#define DO_BUY                          StrToTime("2018.07.16 18:45")
#define DO_SELL                         0//StrToTime("2018.07.16 18:45")
#define TEST_LOT_SIZE                   0.01

int     testOrderOpened                 = false;

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
input double                TRAIL_STOP          = 200;
input INTERVAL_INDEX        BASE_INTERVAL       = M15;

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

input ENUM_MA_METHOD        MA_METHOD           = MODE_EMA;

/* Bollinger band definitions. */
#define BB_VALUES                       3
#define BB_UPPER(intv)                  (bb[(intv * BB_VALUES)])
#define BB_MAIN(intv)                   (bb[(intv * BB_VALUES) + 1])
#define BB_LOWER(intv)                  (bb[(intv * BB_VALUES) + 2])
#define BB_UPPER_CALC(intv, shift)      (iBands(NULL, inervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, BB_APPLIED_PRICE, MODE_UPPER, shift))
#define BB_MAIN_CALC(intv, shift)       (iBands(NULL, inervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, BB_APPLIED_PRICE, MODE_MAIN, shift))
#define BB_LOWER_CALC(intv, shift)      (iBands(NULL, inervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, BB_APPLIED_PRICE, MODE_LOWER, shift))

/* Stochastic definitions. */
#define ST_VALUES                       3
#define ST_MAIN(intv)                   (st[(intv * ST_VALUES)])
#define ST_SIGNAL(intv)                 (st[(intv * ST_VALUES) + 1])
#define ST_DIR(intv)                    (st[(intv * ST_VALUES) + 2])
#define ST_MAIN_CALC(intv, shift)       (iStochastic(NULL, inervals[intv], ST_K, ST_D, ST_S, ST_METHOD, ST_APPLIED_PRICE, MODE_MAIN, shift))
#define ST_SIGNAL_CALC(intv, shift)     (iStochastic(NULL, inervals[intv], ST_K, ST_D, ST_S, ST_METHOD, ST_APPLIED_PRICE, MODE_SIGNAL, shift))

/* MA definitions. */
#define MA21_CALC(intv, shift)          (iMA(NULL, inervals[intv], 21, 0, MA_METHOD, PRICE_OPEN, shift))
#define MA7_CALC(intv, shift)           (iMA(NULL, inervals[intv], 7, 0, MA_METHOD, PRICE_OPEN, shift))

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
    int total;
    double trailStop;
    
    /* Verify that we have enoght data on the chart. */
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
    
    /* Calculate the total number of opened orders. */
    total = OrdersTotal();
    
    if (testOrderOpened == false)
    {
        /* Open test orders if needed. */
        doTest(total);
    }
    
    /* Traverse through all the orders. */
    for (int cnt = 0; cnt < total; cnt++)
    {
        /* Select the first order and verify if is the the right symbol and type. */
        if (!OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) || 
            (OrderSymbol() != Symbol()) ||
            ((OrderType() != OP_SELL) && (OrderType() != OP_BUY)))
        {
            /* Move to next order. */
            continue;
        }

        /* If this is a long position. */
        if (OrderType() == OP_BUY)
        {
            
            /* If Bid price is greater than the MA21. */
            if (Bid > MA21_CALC(BASE_INTERVAL, 0))
            {
                /* Calculate trail stop from the MA21. */
                trailStop = MA21_CALC(BASE_INTERVAL, 0);
            }
            else
            {
                /* Calculate trail stop from the Bid price. */
                trailStop = Bid - (TRAIL_STOP * Point);
            }

            /* If stop loss can be updated. */
            if ((OrderStopLoss() < trailStop) || (OrderStopLoss() == 0))
            {
                Print("Updating SL of \"", OrderTicket(), "\" as \"", OrderStopLoss(), "\" -> \"", trailStop, "\"");
                
                /* Update trail stop. */
                if (!OrderModify(OrderTicket(), OrderOpenPrice(), trailStop, OrderTakeProfit(), 0, Green))
                {
                    Print("OrderModify error ",GetLastError());
                }
            }
        }
        
        /* If this is a short position. */
        else if (OrderType() == OP_SELL)
        {
            /* If Ask price is less than the MA21. */
            if (Ask < MA21_CALC(BASE_INTERVAL, 0))
            {
                /* Calculate trail stop from the MA21. */
                trailStop = MA21_CALC(BASE_INTERVAL, 0);
            }
            else
            {
                /* Calculate trail stop from the Ask price. */
                trailStop = Ask + (TRAIL_STOP * Point);
            }
            
            /* Normalize the trail stop. */
            trailStop = NormalizeDouble(trailStop, Digits);
            
            /* If stop loss can be updated. */
            if ((OrderStopLoss() > trailStop) || (OrderStopLoss() == 0))
            {
                Print("Updating SL of \"", OrderTicket(), "\" as \"", OrderStopLoss(), "\" -> \"", trailStop, "\"");
                
                /* Update trail stop. */
                if (!OrderModify(OrderTicket(), OrderOpenPrice(), trailStop, OrderTakeProfit(), 0, Red))
                {
                    Print("OrderModify error ",GetLastError());
                }
            }
        }
    }

    /* Print the collected comment. */
    Comment(comment);
}

/**
 * This retrun true if conditions match for a long position to close.
 */
void doTest(int numOrders)
{
    int ticket;
    
    /* If we have not opened an order yet. */
    if (numOrders < 1)
    {
        /* Test if we need to open a buy order. */
        if ((DO_BUY > 0) && (TimeCurrent() >= DO_BUY))
        {
            /* Open a buy order. */
            ticket = OrderSend(Symbol(), OP_BUY, TEST_LOT_SIZE, Ask, 3, 0, 0, "OPTIMAL_TEST", MAGIC, 0, Green);
            
            if ((ticket > 0) && OrderSelect(ticket ,SELECT_BY_TICKET, MODE_TRADES))
            {
                Print("SELL order opened : ", OrderOpenPrice());
            }
            else
            {
                Print("Error opening SELL order : ", GetLastError());
            }
            
            /* Test order was opened. */
            testOrderOpened = true;
        }
        
        /* Test if we need to open a sell order. */
        if ((DO_SELL > 0) && (TimeCurrent() >= DO_SELL))
        {
            /* Open a sell order. */
            ticket = OrderSend(Symbol(), OP_SELL, TEST_LOT_SIZE, Bid, 3, 0, 0, "OPTIMAL_TEST", MAGIC, 0, Red);
            
            if ((ticket > 0) && OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
            {
                Print("SELL order opened : ", OrderOpenPrice());
            }
            else
            {
                Print("Error opening SELL order : ", GetLastError());
            }
            
            /* Test order was opened. */
            testOrderOpened = true;
        }
    }
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
    /* Traverse through all the intervals. */
    for (int i = 0; (i < NUM_INTERVALS); i++)
    {
        /* Add interval string. */
        comment += "[" + inervalStrings[i] + "] ";

        /* Add Bollinger for this interval. */
        comment += ((Close[0] > BB_UPPER(i)) ? "*" : " ") + DoubleToStr(BB_UPPER(i), 2);
        comment += (((Close[0] <= BB_UPPER(i)) && (Close[0] > BB_MAIN(i))) ? " * " : "   ") + DoubleToStr(BB_MAIN(i), 2);
        comment += (((Close[0] <= BB_MAIN(i)) && (Close[0] > BB_LOWER(i))) ? " * " : "   ") + DoubleToStr(BB_LOWER(i), 2);
        comment += ((Close[0] < BB_LOWER(i)) ? " *" : "  ");

        /* Add stochastic data. */
        comment += ((ST_DIR(i) == 1) ? "U" : "D");
        
        /* Terminate this line. */
        comment += "\n";
    }
}
