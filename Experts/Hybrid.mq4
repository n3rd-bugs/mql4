//+------------------------------------------------------------------+
//|                                                       Hybrid.mq4 |
//|                                     Copyright 2018, Usama Masood |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Usama Masood"
#property link      "https://github.com/n3rd-bugs/mql4"
#property version   "1.0"
#property strict

/* Definitions. */
#define NUM_INTERVALS               9
#define MAGIC                       0x145211

/* Bollinger band definitions. */
#define BB_VALUES                   3
#define BB_UPPER(intv)              (bb[(intv * BB_VALUES)])
#define BB_MAIN(intv)               (bb[(intv * BB_VALUES) + 1])
#define BB_LOWER(intv)              (bb[(intv * BB_VALUES) + 2])
#define BB_UPPER_CALC(intv, shift)  (iBands(NULL, inervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_UPPER, shift))
#define BB_MAIN_CALC(intv, shift)   (iBands(NULL, inervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_MAIN, shift))
#define BB_LOWER_CALC(intv, shift)  (iBands(NULL, inervals[intv], BB_PERIOD, BB_DEVIATION, BB_SHIFT, PRICE_CLOSE, MODE_LOWER, shift))

/* Stochastic definitions. */
#define ST_VALUES                   3
#define ST_MAIN(intv)               (st[(intv * ST_VALUES)])
#define ST_SIGNAL(intv)             (st[(intv * ST_VALUES) + 1])
#define ST_DIR(intv)                (st[(intv * ST_VALUES) + 2])
#define ST_MAIN_CALC(intv, shift)   (iStochastic(NULL, inervals[intv], ST_K, ST_D, ST_S, MODE_SMA, 0, MODE_MAIN, shift))
#define ST_SIGNAL_CALC(intv, shift) (iStochastic(NULL, inervals[intv], ST_K, ST_D, ST_S, MODE_SMA, 0, MODE_SIGNAL, shift))

/* RSI definitions. */
#define RSI_VALUES                  1
#define RSI(intv)                   (rsi[(intv * RSI_VALUES)])
#define RSI_CALC(intv, shift)       (iRSI(NULL, inervals[intv], RSI_PERIOD, PRICE_CLOSE, shift))

/* RSI ST definitions. */
#define RSI_ST_CALC(intv, shift)    (RSI_CALC(intv, shift) * ST_MAIN_CALC(intv, shift))

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
input double            LOT_SIZE        = 0.1;
input double            TAKE_PROFIT     = 0;
input double            TRAIL_STOP      = 100;
input INTERVAL_INDEX    BASE_INTERVAL   = M30;
input int               BB_PERIOD       = 10;
input int               BB_DEVIATION    = 2;
input int               BB_SHIFT        = 0;
input int               ST_K            = 5;
input int               ST_D            = 3;
input int               ST_S            = 3;
input int               ST_UP           = 80;
input int               ST_DOWN         = 20;
input int               RSI_PERIOD      = 14;
input int               RSI_UP          = 70;
input int               RSI_DOWN        = 30;

/* Shared/global variable definitions. */
double bb[];
double st[];
double rsi[];
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
    int total, ticket;
    
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
    
    /* If we don't have any open order. */
    if (total < 1)
    {
        /* Test if we can open a long position. */
        if (testLong())
        {
            ticket = OrderSend(Symbol(), OP_BUY, LOT_SIZE, Ask, 3, 0, (TAKE_PROFIT > 0) ? Ask + (TAKE_PROFIT * Point) : 0, "macd sample", MAGIC, 0, Green);
            if (ticket > 0)
            {
                if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                {
                    Print("BUY order opened : ",OrderOpenPrice());
                }
            }
            else
            {
                Print("Error opening BUY order : ",GetLastError());
            }
            return;
        }
        
        /* Test if we can open a short position. */
        if (testShort())
        {
            ticket = OrderSend(Symbol(), OP_SELL, LOT_SIZE, Bid, 3, 0,  (TAKE_PROFIT > 0) ? Bid - (TAKE_PROFIT * Point) : 0, "macd sample", MAGIC, 0, Red);
            if (ticket > 0)
            {
                if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                {
                    Print("SELL order opened : ",OrderOpenPrice());
                }
            }
            else
            {
                Print("Error opening SELL order : ",GetLastError());
            }
        }
    }
    
    /* Traverse through all the orders. */
    for (int cnt = 0; cnt < total; cnt++)
    {
        /* Select the first order and verify if is the the right symbol and type. */
        if (!OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) || 
            (OrderSymbol() != Symbol()) ||
            ((OrderType() != OP_SELL) && (OrderType() != OP_BUY)) ||
            (OrderMagicNumber() != MAGIC))
        {
            /* Move to next order. */
            continue;
        }

        /* If this is a long position. */
        if (OrderType() == OP_BUY)
        {
            /* Should a long position be closed. */
            if (doCloseLong())
            {
                /* Close this long position. */
                if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet))
                {
                    Print("OrderClose error ",GetLastError());
                }
                return;
            }
            
            //--- check for trailing stop
            if (TRAIL_STOP > 0)
            {
                if (Bid - OrderOpenPrice() > Point * TRAIL_STOP)
                {
                    if (OrderStopLoss() < Bid - (Point * TRAIL_STOP))
                    {
                        //--- modify order and exit
                        if (!OrderModify(OrderTicket(), OrderOpenPrice(), Bid - (Point * TRAIL_STOP), OrderTakeProfit(), 0, Green))
                        {
                            Print("OrderModify error ",GetLastError());
                        }
                        
                        return;
                    }
                }
            }
        }
        
        /* If this is a short position. */
        else if (OrderType() == OP_SELL)
        {
            /* Should a short position be closed. */
            if (doCloseShort())
            {
                /* Close this short position. */
                if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet))
                {
                    Print("OrderClose error ",GetLastError());
                }
                return;
            }
            //--- check for trailing stop
            if (TRAIL_STOP > 0)
            {
                if ((OrderOpenPrice() - Ask) > (Point*TRAIL_STOP))
                {
                    if ((OrderStopLoss() > (Ask + (Point * TRAIL_STOP))) || (OrderStopLoss() == 0))
                    {
                        //--- modify order and exit
                        if (!OrderModify(OrderTicket(), OrderOpenPrice(), Ask + (Point * TRAIL_STOP), OrderTakeProfit(), 0, Red))
                        {
                            Print("OrderModify error ",GetLastError());
                        }
                        return;
                    }
                }
            }
        }
    }

    /* Print the collected comment. */
    Comment(comment);
}

/**
 * This retrun true if conditions match for a long position.
 */
int testLong()
{   
    return (0);
}

/**
 * This retrun true if conditions match for a long position to close.
 */
int doCloseLong()
{
    return (0);
}

/**
 * This retrun true if conditions match for a short position.
 */
int testShort()
{
    return (0);
}

/**
 * This retrun true if conditions match for a short position to close.
 */
int doCloseShort()
{
    return (0);
}
/**
 * This will initialize various indicators.
 */
void initializeIndicators()
{
    /* Resize data arrays with required size. */
    ArrayResize(bb, NUM_INTERVALS * BB_VALUES);
    ArrayResize(st, NUM_INTERVALS * ST_VALUES);
    ArrayResize(rsi, NUM_INTERVALS * RSI_VALUES);
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
        
        /* Gather RSI data. */
        RSI(i)          = RSI_CALC(i, 0);
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
