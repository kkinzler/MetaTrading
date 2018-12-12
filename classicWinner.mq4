//this is the best day every 

#property copyright "Copy-Right 2018 kkinzler"
#property description "This will be a simple demonstration of how to write an expert advisor"
#property description "in MQL4. The advisor will use technical indicators to generate buy and"
#property description "sell signals and determine an exit strategy."


double risk = .02; //percent of balance to risk on each trade
double stopLoss = 0.0; //determined when opening position
double takeProfit = 0.0; //determined when opening position

int openPosition = 0; //set to 1 when position opens
int startHour = 7; //hour to start trading
int endHour = 16; //hour to stop trading

string EAName = "simpleDemo"; //name used so you can tell which advisor made which trade
int Magic = 38493847; //magic number used to verify you are accessing your position
double LotDigits = 2; //brokers demand you round your position size to a certain decimal point
                      //this is determined by by whether your broker trades in micro-lots
int slippage = 2; //between getting the latest tick value and placing an order the price might 
                  //have changed. this is the amount in pips(or points) that the price is
                  //allowed to change and you'll still want to make the trade

int ATRPeriod_1 = 14; //parameters for Average True Range indicator. used to find exit points
int ATRPeriod_2 = 5; 

extern int FastMAPeriod = 9;
extern int SlowMAPeriod = 30;
extern double ATRCoef = 0.5;
extern double trailCoef = 3.0;
extern bool partialExit = true;

int macdSignal = 0;
int hour = 60;
int day = 1440;


int init(){
    //usually this function that runs once when it's placed on a currency pair
    //sets valuable information based on parameters specific to your broker.
    //since i am writing this for myself i will hard code when necessary
    //to my brokers specs.
return 0;
}

int start(){

   int lookForTrade = manageOpenOrders(); //check for open orders and whether it's ok to look for a new order

   if(lookForTrade == 0) //if zero is returned not ok to open new order
        return 0;




return 0;
}

int manageOpenOrders(){
    int trading = tradeAllowed();

    if(trading == 0){//trading and open positions not allowed
        close();
        return 0;
    }

    if(trading == 2){ //not ok to open position but ok to trail
        if(openPosition) // just check status of open position and return
            checkExits();
    return 0;
    }

    if(trading == 1){ //ok to open position if no position exists
        if(openPosition){ //check status of open position and return
            checkExits();
            return 0;
        }
    }

return 1; //ok to look for open positions if none already open
}

int checkExits(){

    int newBar = checkNewBar();

    if(newBar == 0) //wait for new bar to check on orders
        return 0;
    
    int orderClosed = lookForClose(); //return 0 = no close; 1 = position closed; 2 = trail either began or continued

    if(orderClosed == 1){
        stopLoss = 0.0;
        takeProfit = 0.0;
        openPosition = 0;
    }

return 0;
}


int lookForClose(){

    int orders;
    double ATR = ATRStopLoss(ATRPeriod_1, ATRPeriod_2, trailCoef);
    datetime closeTime;
    int ticket = getTicket();

   
    RefreshRates();
    orders = OrdersTotal();
    OrderSelect(ticket, SELECT_BY_TICKET);
    closeTime = OrderCloseTime();

    if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && closeTime == 0){
                if(OrderType() == OP_BUY){
                    //might want to get rid of SL and calculate a stoploss off the 
                    //ATR every time you enter the TrailOrder function
                    if(Bid <= SL){
                        close();
                        SL = 0;
                        trailing = false;
                        startTrail = 0.0;
                        return false;
                    }
                    if(trailing){
                        if(Bid >= SL + (ATR))//every ATR is divided by 2 so just go back and divide them
                            SL = Bid - (ATR);
                    }

                    else    
                        if(Bid >= startTrail){
                            SL = Bid - (ATR);//ATR is used to set price but i dont know
                            trailing = true;   //SL = Bid - (ATR/2)
                        }
                }
                if(OrderType() == OP_SELL)
                {

                    if(Ask >= SL){
                        close();
                        SL = 0;
                        trailing = false;
                        startTrail = 0.0;
                        return false;
                    }
                    
                    if(trailing){
                        if(Ask <= SL - (ATR))
                            SL = Ask + (ATR);
                    }

                    else    
                        if(Ask <= startTrail){
                            SL = Ask + (ATR);//ATR is used to set price but i dont know
                            trailing = true;   // SL = Ask + (ATR/2);
                        }
                  return true;
                }
    }
//printf("returning false");
return false;
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

    int path = 1; //initially path is 1 which means to look for positions to open
 
    if(Hour() < startHour || Hour() > endHour) 
         path = 2; //if trading day is done or hasn't started you can trail open
                   //orders but cannot open any new orders. 

    if(DayOfWeek() == 5 && Hour() >= endHour)
        path = 0; //don't hold positions over the weekend. return 0 so main knows 
                  //to close any open orders 

    if((DayOfWeek() == 5 && Day() < 8))
        path = 0; //don't trade release of non-farm payroll report (first friday of month)

    if(Bars < 30)
        path = 0; //never came across a use case for this case check. but to make sure you
                  //have enough bars in the que to even do technical analysis

return path;
}
