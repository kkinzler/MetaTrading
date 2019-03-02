//this is the best day ever

#property copyright "Copy-Right 2018 kkinzler"
#property description "This will be a simple demonstration of how to write an expert advisor"
#property description "in MQL4. The advisor will use technical indicators to generate buy and"
#property description "sell signals and determine an exit strategy."


double risk = .02; //percent of balance to risk on each trade
double stopLoss = 0.0; //determined when opening position
double takeProfit = 0.0; //determined when opening position
double newStopLoss = 0.0; //set newStopLoss off open price in order to cover failed trades + spread
double newTakeProfit = 0.0;

int positionOpen = 0; //set to 1 when position opens
int startHour = 7; //hour to start trading
int endHour = 16; //hour to stop trading

string EAName = "simpleDemo"; //name used so you can tell which advisor made which trade
int Magic = 38493847; //magic number used to verify you are accessing your position
double LotDigits = 2; //brokers demand you round your position size to a certain decimal point
                      //this is determined by by whether your broker trades in micro-lots
int slippage = 0; //between getting the latest tick value and placing an order the price might 
                  //have changed. this is the amount in pips(or points) that the price is
                  //allowed to change and you'll still want to make the trade

int ATRPeriod_1 = 14; //parameters for Average True Range indicator. used to find exit points
int ATRPeriod_2 = 5; 

int init(){
    //usually this function runs once when EA is placed on a currency pair and 
    //sets valuable information based on parameters specific to your broker.
    //since i am writing this for myself i will hard code when necessary
    //to my brokers specs.
return 0;
}

int start(){
    
    int toDo = tradeAllowed(); //check for open orders and whether it's ok to look for a new order
    int signal;

    if(toDo == 86){
        close();
    if(toDo == 1)
        signal = generateTradeSignal();
    if(toDo == 2)
        checkExits();
    if(toDo == 0)
        //do nothing on 0

    if(signal)
        gamble(signal);

return 0;
}

int checkExits(){

    //check orders at the start of a new bar
    if(!checkNewBar() == 0)
        return 0;

    int orderClosed = lookForClose();
        //1 == order was closed
        //0 == order was modified or nothing was changed

    if(orderClosed)
        resetGlobalVars();

return 0;
}


int lookForClose(){

    int ticket = getTicket();
   
    RefreshRates();
    OrderSelect(ticket, SELECT_BY_TICKET);

    if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic){

        if(OrderType() == OP_BUY){
            if(Bid <= stopLoss){
                close();
                return 1;
            }
            if(Bid >= takeProfit){
                setNewExits();
                return 0;
            }
        }

        if(OrderType() == OP_SELL){
            if(Ask >= stopLoss){
                close();
                return 1;
            }
            
            if(Ask <= startTrail){
                setNewExits();
                return 0;
            }
        }
    }

return 0;
}

bool checkNewBar(){
   int ticker = iVolume(NULL, 0, 0); //when iVolume is 0 no ticks have been registered
                                     //to the bar, meaning it is brand new
    
    if(ticker > 1)
        return 0;
    else
        return 1;
}


//when trade, stop trading or close positions
int tradeAllowed(){

    if(positionOpen && closeOrders())
        return 86;

    if(positionOpen && !closeOrders())
        return 2;

    if(!positionOpen && checkTradeSignal())
        return 1;
    
    if(Bars < 30)
        path = 0; //never came across a use case for a bar check. but to make sure you
                  //have enough bars in the queue to even do technical analysis
return 0;
}

int closeOrders(){
    //if end of Friday don't hold positions over the weekend. Close.
    if(DayOfWeek() == 5 && Hour() >= endHour)
        return 1;
    //if first Friday of the month don't trade payroll report. Close.
    if(DayOfWeek() == 5 && Day() < 8)
        return 1;
return 0;
}

int checkTradeSignal(){
    //only trade in liquid markets. if outside trading window don't look for trade signals.
    if(Hour() >= startHour && Hour() <= endHour) 
        return 1;
    
    if(closeOrders())
        return 1;
return 0;
}

int getTicket(){

   int ticket = 0;
   int count = 0;
   int ordersTotal = OrdersTotal();
   
   if(ordersTotal == 0)
      return ticket;
    //loop thru all open orders of all securities until the one for the
    //current chart is found and return it.      
   for(count; count <= ordersTotal; ++count){
      OrderSelect(count, SELECT_BY_POS);
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic){
         ticket = OrderTicket();
         count = 666;
      }
   }   

return ticket;
}

bool newBar(){
    int ticker = iVolume(NULL, 0, 0);

    if(ticker > 1)
        return 0;
return 1;
}

int resetGlobalVars(){

        stopLoss = 0.0;
        takeProfit = 0.0;
        newStopLoss = 0.0;
        newTakeProfit = 0.0;
        openPosition = 0;
}

int close(){

    int error = 0;
    bool closed = false;
    int attempts = 10;
    datetime closeTime;
    double ClosePrice = 0.0;
    int ticket = getTicket();

    //funny because without checking for whether or not there were any orders
    //ie. whether a SL/TP had closed an order, my while loop would run 
    //forever trying to close an order that no longer exists
    // printf("OrdersTotal() = %i", OrdersTotal());
    if(OrdersTotal() == 0)
        return 0;
        
        // printf("ticket = %i", ticket);
        OrderSelect(ticket, SELECT_BY_TICKET);
        //  printf("ticket() = %i", OrderTicket());
        closeTime = OrderCloseTime();
        // printf("closetime: %i", closeTime);
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && closeTime == 0){
    // printf("lots = %f", OrderLots());
    //  printf("NormalizeDouble(OrderLots(), 2)/2 = %f", NormalizeDouble(OrderLots()/2, 2));

            if(OrderType() == OP_BUY){
        printf("closing buy at: %f", Bid);

                while(attempts > 0){  
                    RefreshRates();
                    ClosePrice=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Digits);
                    closed = OrderClose(ticket, OrderLots(), ClosePrice, 2, clrDarkOrange);
                    --attempts;
                    error = GetLastError();
                    if(error)
                        printf("last error code: %i", error);
                    if(closed){
                        ticket = 0;
                        return 1;
                    }
                }
            }

            if(OrderType() == OP_SELL){
    printf("closing sell at: %f", Ask);

                while(attempts > 0){
                    RefreshRates();
                    ClosePrice=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),Digits);
                    closed = OrderClose(ticket, OrderLots(), ClosePrice, 2, clrDarkOrange);
                    --attempts;
                    
                    error = GetLastError();
                    if(error != 0)
                        printf("last error code: %i", error);
                        
                    if(closed){
                        ticket = 0;
                        return 1;
                    }
                }
            }
        }
return 1;
}
