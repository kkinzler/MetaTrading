//in lookForClose() user needs to decide whether they want to 
//trail the price once takeProfit level is reached or close
//the order.
//in generateTradeSignal() 

#property copyright "Copy-Right 2018 kkinzler"
#property description "This will be a simple demonstration of how to write an expert advisor"
#property description "in MQL4. The advisor will use technical indicators to generate buy and"
#property description "sell signals and determine an exit strategy."


double risk = .02; //percent of balance to risk on each trade
double stopLoss = 0.0; //determined when opening position
double takeProfit = 0.0; //determined when opening position
double newStopLoss = 0.0; //set newStopLoss off open price in order to cover failed trades + spread
double newTakeProfit = 0.0;

int openPosition = 0; //set to 1 when position opens
int startHour = 13; //hour to start trading
int endHour = 16; //hour to stop trading

string EAName = "classicWinner"; //name used so you can tell which advisor made which trade
int Magic = 38493847; //magic number used to verify you are accessing your position
double LotDigits = 2; //brokers demand you round your position size to a certain decimal point
                      //this is determined by by whether your broker trades in micro-lots
int slippage = 0; //between getting the latest tick value and placing an order the price might 
                  //have changed. this is the amount in pips(or points) that the price is
                  //allowed to change and you'll still want to make the trade

//this is hardcoded into the risk management function
//that is you might want to a different stratey for 
//deciding your exit levels and determining position size
int ATRPeriod_1 = 14; //parameters for Average True Range indicator. used to find exit levels
int ATRPeriod_2 = 5; 

int init(){
    //usually this function runs once when EA is placed on a currency pair and 
    //sets valuable information based on parameters specific to your broker.
    //since i am writing this for myself i will hard code when necessary
    //to my brokers specs.
return 0;
}

//why aren't i using ticks() here. when I check the ticks for a new bar?
//is that just an MQL5 function??
int start(){
    //I could check for a new bar here and then exit if there isn't anything to do
    //but it's probably best to leave the check for inside the exit strategy functions
    //in case I want to look for close inside a bar rather than at the start

    int toDo = tradeAllowed(); //check for open orders and whether it's ok to look for a new order
    int signal = 0;

    if(toDo == 86){//close open orders. must be the weekend
        close();
        resetGlobalVars();//close() and resetGlobalVariables() always called in tandem
        return 0;
    }

    if(toDo == 2){//order is open so look for close or to adjust stoploss/takeprofit or change position size
        checkExits();    
        return 0;
    }

    if(toDo == 1){//look for a new order to open
        if(checkNewBar())
            signal = generateTradeSignal();
    }

    if(toDo == 0)//do nothing on 0

    if(signal)
        gamble(signal);

return 0;
}


int checkExits(){

    //check orders at the start of a new bar
    //this is called inside checkExits() in case you want 
    //to change strategy to check on new bar or every tick etc...
    if(!checkNewBar())
        return 0;

    int orderClosed = lookForClose();
        //1 == order was closed
        //0 == order was modified or nothing was changed

    if(orderClosed)
        resetGlobalVars();//again, calling these two functions in tandem

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
                setNewExits();//this strategy trails the price. other option is to close
                              //once takeProfit has been reached. 
                return 0;
            }
        }

        if(OrderType() == OP_SELL){
            if(Ask >= stopLoss){
                close();
                return 1;
            }
            
            if(Ask <= takeProfit){
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
        return 0;//intrabar
return 1;//new bar found
}


//when trade, stop trading or close positions
int tradeAllowed(){

    if(positionOpen && closeOrders())//position is open but its the weekend so close
        return 86;

    if(positionOpen && !closeOrders())//position is open so return and look for close
        return 2;

    if(!positionOpen && checkTradeSignal())//no open position so look check if you are in
        return 1;                          //the trading window you've tested on (eg. 9:00am - 12:00pm)
        
    
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
//you might also want to prohibit holding orders over night in this function
return 0;
}

int checkTradeSignal(){
    if(closeOrders())//first check if it's first Friday before looking for the time
        return 0;

    //only trade in liquid markets. if outside trading window don't look for trade signals.
    if(Hour() >= startHour && Hour() <= endHour) 
        return 1;
return 0;
}

int getTicket(){

   int ticket = 0;
   int count = 0;
   int ordersTotal = OrdersTotal();
   
   if(ordersTotal == 0){
       printf("error retrieving ticket#\tno open orders\n");
       return ticket;
   }
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
    int ticker = iVolume(NULL, 0, 0);//iVolume() returns number of ticks in current bar
                                     //if 0 you are at the beginning of a new bar

    if(ticker > 1)
        return 0;
return 1;
}

//reset all data on closed order needed to manage
//the recently closed order
int resetGlobalVars(){

        stoploss = 0.0;
        takeProfit = 0.0;
        newStopLoss = 0.0;
        newTakeProfit = 0.0;
        openPosition = 0;

return 0;
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
