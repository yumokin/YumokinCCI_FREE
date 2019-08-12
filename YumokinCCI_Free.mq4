//+------------------------------------------------------------------+
//|                                                   YumokinCCI.mq4 |
//|                             Copyright (c) 2018,    fx.yumokin.jp |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2014, yumokin.jp"
#property link      "https://fx.yumokin.jp"
#property version     "1.60 free"
#property strict

#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5

//Product edition (0 demo version, 1 product version)
int ProductEdition=1;
extern int FUNDA = 0;
extern int magic = 20190609;
int magicST1;
int magicST2;
double transLots;
extern double lots1=0.1;
extern double lots2=0.2;
int maxCnt;
int maxCntST1=1;
int maxCntST2=1;
extern int profitPips=0;
extern double losscutPips=100;
double BreakEven = 10;
double TrailingStop = 10;
extern int trapIntervalPips = 15;
int DigitsMinus=1;

int displayMode=0;
extern int TRADEOFFMODE=1;
extern int EntryStartHourGMT=6;
extern int EntryEndHourGMT=15;
extern int FridayTejimaiMode=1;
extern int FridayTejimaiHourGMT=9;
extern int MondayTRADEOFF=0;
extern int TuesdayTRADEOFF=0;
extern int WednesdayTRADEOFF=0;
extern int ThursdayTRADEOFF=0;
extern int FridayTRADEOFF=1;
extern int NewYearTRADEOFF=1;

int pyramiding=1;

//TIMEFRAME
int timeframeSmall=15;
int timeframeMiddle=60;
int timeframeLarge=240;

bool isBuyTrap = true;
int doOrderRangePips = 300;
int slippage = 3;

color ArrowColor[6] = {Green, Red, Green, Red, Green, Red};
double pointPerPips;
int slippagePips;

int magicArray[];
int ticketArray[];
string symbolCode;

extern int entryPattern=2;
extern int volPattern=2;
int divMinute=60;
int divMode=1;
//0:Close[0]+-α,1:HighestLowest+-α,2:Close[0],3:ASKBID
extern int priceMode=0;
int expireMinute=120;

//ExitMode
extern int exitMode=1;
extern int exitPatternMACD=3;

//MACD2
int fastMACD = 12;
int slowMACD = 26;
int signalMACD = 9;
int MACDshift=0;
int isMACDSmall=0;
int isMACDMiddle=0;
int isMACDLarge=0;
double MACDBound=0;
int MACDapplied_price=0;

//CCI
int fastCCI=21;
int CCIshift=0;
int isCCISmall=0;
int isCCIMiddle=0;
int isCCILarge=0;
extern double CCIBound=0;
int CCIapplied_price=0;

datetime ServerDateTime;
int ServerWeek;
int ServerHour;
int ServerHourGMT;
int ServerMinute;
extern int TestGMTOffset = 2;

ENUM_SYMBOL_INFO_INTEGER TradeExeMode;

//CandleLength
int isCandleLengthSmall;
int isCandleLengthMiddle;
int isCandleLengthLarge;
extern double squeezePips=100;
extern int shiftCandleLength=1;

int UseBarTime=1;
datetime BarTime = 0;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //Trade permission check
    if(IsTradeAllowed() == false) {
        Print("Trade not Allowed");
        return(INIT_FAILED);
    }
    //Available check only if the product is a demo version
    if(ProductEdition==0){
        if(EnableCheck()==false){
            return(INIT_FAILED);
        }
    }
    
    int mult = 1;
    if(Digits == 3 || Digits == 5) {
        mult = 10;
    }
    pointPerPips = Point * mult;
    slippagePips = slippage * mult;
    
    symbolCode=Symbol();
    
    //Hide indicator
    HideTestIndicators(true);    
    
    //Get transaction execution mode
    TradeExeMode=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_EXEMODE);
    Print("TradeExeMode=",TradeExeMode);

    maxCnt=maxCntST1+maxCntST2;
    magicST1=magic;//magicST1=20160201
    magicST2=magic+maxCntST1;//magicST2=20160201+1=20160202
            
    return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

    return;
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    //バー形成時に１回だけ実施する
    if(UseBarTime==1){
        // 始値でなければ終了
        if(BarTime == Time[0]){
            return;
        }
        BarTime = Time[0];
    }
    
    int magicNumber;
    int ret;
    int entry = 0;
    int i;
    
    //Comment initialization
    if(displayMode==1){
        CommentEX();
    }

    //MACD2
    isMACDSmall = CheckMACD2(timeframeSmall,fastMACD,slowMACD,signalMACD,MACDshift,MACDBound,MACDapplied_price);
    isMACDMiddle = CheckMACD2(timeframeMiddle,fastMACD,slowMACD,signalMACD,MACDshift,MACDBound,MACDapplied_price);
    isMACDLarge = CheckMACD2(timeframeLarge,fastMACD,slowMACD,signalMACD,MACDshift,MACDBound,MACDapplied_price);     

    //CCI2
    isCCISmall = CheckCCI2(timeframeSmall,fastCCI,CCIshift,CCIBound,CCIapplied_price);
    isCCIMiddle = CheckCCI2(timeframeMiddle,fastCCI,CCIshift,CCIBound,CCIapplied_price);
    isCCILarge = CheckCCI2(timeframeLarge,fastCCI,CCIshift,CCIBound,CCIapplied_price); 
    
    //CandleLength
    isCandleLengthSmall = CheckCandleLength(timeframeSmall,shiftCandleLength,squeezePips);
    isCandleLengthMiddle = CheckCandleLength(timeframeMiddle,shiftCandleLength,squeezePips);
    isCandleLengthLarge = CheckCandleLength(timeframeLarge,shiftCandleLength,squeezePips); 
    
    //EXIT
    if(exitMode==0){
    }
    else if(exitMode==1){
        for(i=0; i < maxCnt; i++) {
            CloseByMACD(magic + i, exitPatternMACD);
        }
    }
    
    //TICKET INFO    
    int ticketCnt=0;
    int posCnt=0;
    int posCntBuy=0;
    int posCntSell=0;
    int ordCnt=0;

    ret = GetTicketInfo(magic,maxCnt,ticketCnt,posCnt,posCntBuy,posCntSell,ordCnt);
    //Print("ticketCnt=",ticketCnt);
    //Print("posCnt=",posCnt);
    //Print("posCntBuy=",posCntBuy);
    //Print("posCntSell=",posCntSell);
    //Print("ordCnt=",ordCnt);
    
    if(TRADEOFFMODE==1){
        //TRADE OFF
        ret = CheckTradeOffTime(ordCnt);
        if(ret == 1){
            //safety
            return;
        }
    }

    //Get position elapsed time
    //ret = GetOrderOpenTime2(magic,divMinute,divMode);
    //if(ret==-1){
    //    return;
    //}
    
    //Get ticket information
    if(initOrderTicketInfo() == false){
        return;
    }

    //DISPLAY START
    if(displayMode==1){
    }        
    
    //ticketCntは0-maxCntを取る。
    if(ticketCnt >= maxCnt){
        return;    
    }
        
    //ENTRY START
    if(entryPattern==1){
        if(isMACDMiddle >= 3 && isCCISmall == 3){
            entry = 1;
        }
        else if(isMACDMiddle <= -3 && isCCISmall == -3){
            entry = -1;
        }
    }
    else if(entryPattern==2){    
        if( isMACDMiddle >= 3 && isCCIMiddle == 3){
            entry = 1;
        }
        else if(isMACDMiddle <= -3 && isCCIMiddle == -3){
            entry = -1;
        }
    }
    else if(entryPattern==3){    
        if( isMACDMiddle >= 3 && isCCILarge == 3){
            entry = 1;
        }
        else if(isMACDMiddle <= -3 && isCCILarge == -3){
            entry = -1;
        }
    }    
    else if(entryPattern==4){
        if(isMACDMiddle >= 3 && isCCISmall == 2){
            entry = 1;
        }
        else if(isMACDMiddle <= -3 && isCCISmall == -2){
            entry = -1;
        }
    }
    else if(entryPattern==5){    
        if( isMACDMiddle >= 3 && isCCIMiddle == 2){
            entry = 1;
        }
        else if(isMACDMiddle <= -3 && isCCIMiddle == -2){
            entry = -1;
        }
    }
    else if(entryPattern==6){    
        if( isMACDMiddle >= 3 && isCCILarge == 2){
            entry = 1;
        }
        else if(isMACDMiddle <= -3 && isCCILarge == 2){
            entry = -1;
        }
    }
    
    //VOLPATTERN
    if(volPattern==1){
        if(entry==1){
            if(isCandleLengthSmall==false){
                entry=0;
            }
        }
        else if(entry==-1){
            if(isCandleLengthSmall==false){
                entry=0;
            }
        }    
    }
    else if(volPattern==2){
        if(entry==1){
            if(isCandleLengthMiddle==false){
                entry=0;
            }
        }
        else if(entry==-1){
            if(isCandleLengthMiddle==false){
                entry=0;
            }
        }    
    }
    else if(volPattern==3){
        if(entry==1){
            if(isCandleLengthLarge==false){
                entry=0;
            }
        }
        else if(entry==-1){
            if(isCandleLengthLarge==false){
                entry=0;
            }
        }    
    }    
    
    //DOTEN
    if(ticketCnt==0){
        transLots=lots1;
    }
    else{
        if(posCntBuy==1 && entry==-1){
            //Doten
            transLots=lots2;
        }
        else if(posCntSell==1 && entry==1){
            //Doten
            transLots=lots2;        
        }
        else{
            return;
        }
    }
            
    //When not in test mode
    if(IsTesting() == false){
        ret = SetFund(entry);
        if(ret==-1){
            Print(symbolCode," is not allowed.");
            return;
        }
    }
    //In test mode
    else{
        ret = SetFundTest(entry);
        if(ret==-1){
            Print(symbolCode," is not allowed.");
            return;
        }
    }
    
    if(entry==1){
    }
    else if(entry==-1){
    }
    else{
        return;
    }
    
    ret = doYumokinCCI(transLots
                    , pyramiding , trapIntervalPips
                    , magic, losscutPips, entry, ticketCnt);
                    
    return;
}

int doYumokinCCI(double lots, int pyramiding, int trapIntervalPips, int magic, double losscutPips, int entry,int ticketCnt) {

    double startPrice;
    double onePips;
    int magicNumber;
    double priceNumber;
    double stopLoss = 0.00;             // openPrice - losscutPips
    string cur;
    
    if(entry == 1){
        if(priceMode==0){
            startPrice = Close[0] + (trapIntervalPips * pyramiding * pointPerPips);
        }
        else if(priceMode==1){
            startPrice = Ask + (trapIntervalPips * pyramiding * pointPerPips);
        }
        else if(priceMode==2){
            startPrice = Close[1];
        }
        else if(priceMode==3){
            startPrice = Ask;
        }        
    }
    else if(entry == -1){
        if(priceMode==0){
            startPrice = Close[0] - (trapIntervalPips * 1 * pointPerPips);
        }
        else if(priceMode==1){
            startPrice = Bid - (trapIntervalPips * 1 * pointPerPips);
        }
        else if(priceMode==2){
            startPrice = Close[1];
        }
        else if(priceMode==3){
            startPrice = Bid;
        }        
    }
    else{  
        return(0);
    }

    for(int i=0; i < pyramiding; i++){

        if(entry == 1){
            isBuyTrap = true;
        }
        else if(entry == -1){
            isBuyTrap = false;
        }
        
        double openPrice = startPrice - trapIntervalPips * i * pointPerPips;
        if(losscutPips != 0){
            if(isBuyTrap == true){
                stopLoss = openPrice - losscutPips * pointPerPips;
            }
            else{
                stopLoss = openPrice + losscutPips * pointPerPips;
            }            
        }
        else{
           stopLoss = 0.00;
        }

        double currentPrice;
        if(isBuyTrap == true){
            currentPrice = Ask;
        } else {
            currentPrice = Bid;
        }
        
        double takeProfit;
        if(profitPips==0){
            takeProfit=0;
        }
        else{
            if(isBuyTrap == true){
                takeProfit = openPrice + profitPips * pointPerPips;  
            } else {
                takeProfit = openPrice - profitPips * pointPerPips;  
            }
        }

        magicNumber = magic + ticketCnt;
        //Entry is not possible with candlesticks where payments are generated by TP or SL
        if(isClosed(magicNumber)==true){
            return(0);
        }
        
        int DigitsNum;
    
        if(Digits == 3 || Digits == 5){
            DigitsNum=Digits-2;
        }
        else{
            DigitsNum=Digits-1;
        }
        
        //Check for tickets with the same magicNumber
        int ticket = getOrderTicket(magicNumber);
        if ( ticket <= 0) {
            ticket = doOrder(lots, openPrice, slippagePips, stopLoss, takeProfit, isBuyTrap, magicNumber);
        }
    }
    
    return(0);

}

int doOrder(double lots, double openPrice, int slippage, double stopLoss, double takeProfit, bool isBuyTrap, int magicNumber) {

    ENUM_ORDER_TYPE tradeType = -1;

    string comment = WindowExpertName();
    
    if(priceMode <= 2){
        if(isBuyTrap && openPrice <= Ask) {
            tradeType = ORDER_TYPE_BUY_LIMIT;
        } else if(isBuyTrap && openPrice > Ask) {
            tradeType = ORDER_TYPE_BUY_STOP;
        } else if(!isBuyTrap && openPrice >= Bid) {
            tradeType = ORDER_TYPE_SELL_LIMIT;
        } else if(!isBuyTrap && openPrice < Bid) {
            tradeType = ORDER_TYPE_SELL_STOP;
        }
    }
    else{
        if(isBuyTrap) {
            tradeType = ORDER_TYPE_BUY;
        } else if(!isBuyTrap) {
            tradeType = ORDER_TYPE_SELL;
        }        
    }
    
    if(tradeType == -1) {
        return(-1);
    }
    
    int errCode = 0;
    int ticket = doOrderSend(tradeType,lots,openPrice,slippage,stopLoss,takeProfit,comment,magicNumber,errCode);

    return(ticket);

}

int doOrderSend(ENUM_ORDER_TYPE type, double lots, double openPrice, int slippage, double stopLoss, double takeProfit, string comment, int magicNumber, int &errCode) {

    openPrice = NormalizeDouble(openPrice, Digits);
    stopLoss = NormalizeDouble(stopLoss, Digits);
    takeProfit = NormalizeDouble(takeProfit, Digits);
        
    if(IsTradeAllowed() == true) {
        RefreshRates();
        int ticket;        
        if(TradeExeMode==0 || TradeExeMode==1){
            ticket = OrderSend(Symbol(), type, lots, openPrice, slippage, stopLoss, takeProfit, comment, magicNumber, TimeCurrent()+(expireMinute * 60), ArrowColor[type]);
            if( ticket > 0) {
                return(ticket);
            }
        }
        else{
            ticket = OrderSend(Symbol(), type, lots, openPrice, slippage, 0, 0, "", magicNumber, 0, ArrowColor[type]);
            if(ticket > 0) {
                if(OrderSelect(ticket,SELECT_BY_TICKET)==true){
                    OrderModify(OrderTicket(),OrderOpenPrice(),stopLoss,takeProfit,TimeCurrent()+(expireMinute * 60),Blue);
                }
                return(ticket);
            }
        }

        errCode = GetLastError();
        Print("openPrice=",openPrice,": stopLoss=",stopLoss,": takeProfit=",takeProfit);
        if(errCode == ERR_INVALID_PRICE || errCode == ERR_INVALID_STOPS) {
            return(-1);
        }
    }

    return(-1);
}

bool initOrderTicketInfo(){

    int orderCount=0;
    int j;
    for(j=0; j < OrdersTotal(); j++) { 
        if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES) == false) return(false);
        if(OrderSymbol() == Symbol()) {
            orderCount++;
        }
    }
    
    ArrayResize(ticketArray,orderCount);
    ArrayResize(magicArray,orderCount);
    orderCount=0;

    for(j=0; j < OrdersTotal(); j++) { 
        if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES) == false) return(false);
        if(OrderSymbol() == Symbol()) {
            ticketArray[orderCount] = OrderTicket();
            magicArray[orderCount] = OrderMagicNumber();
            orderCount++;
        }
    }
    
    return(true);
    
}

int getOrderTicket(int magic){

    int orderCount = 0;
    int ticket = -1;
    for(int i=0; i < ArraySize(magicArray); i++) { 
        if(magic == magicArray[i]) {
            ticket = ticketArray[i];
            orderCount++;
        }
    }

    if(orderCount > 1){
        Print("order duplicate:MagicNumber=",magic,", orderCount=",orderCount);
    }
    
    return(ticket);
} 

int CheckMACD2(int timeframe,int fast,int slow,int signal,int shift,double bound, int applied_price){

    double pointBound = bound * pointPerPips;
   
    double macd_m_0 = iMACD(NULL,timeframe,fast,slow,signal,applied_price,MODE_MAIN,shift);
    double macd_s_0 = iMACD(NULL,timeframe,fast,slow,signal,applied_price,MODE_SIGNAL,shift);
    double macd_m_1 = iMACD(NULL,timeframe,fast,slow,signal,applied_price,MODE_MAIN,shift+1);
    double macd_s_1 = iMACD(NULL,timeframe,fast,slow,signal,applied_price,MODE_SIGNAL,shift+1);
	
    double macd_h_0 = macd_m_0 - macd_s_0;
    //Print("macd_h_0=",macd_h_0);
    double macd_h_1 = macd_m_1 - macd_s_1;
    //Print("macd_h_1=",macd_h_1);

    if(displayMode==1){
        //CommentEX(StringConcatenate("timeframe=",timeframe," ","pointBound=",pointBound," ","macd_h_0=",macd_h_0," ","macd_m_0=",macd_m_0," ","macd_s_0=",macd_s_0));
        //CommentEX(StringConcatenate("timeframe=",timeframe," ","pointBound=",pointBound," ","macd_h_1=",macd_h_1," ","macd_m_1=",macd_m_1," ","macd_s_1=",macd_s_1));        
    }
    
    if(macd_h_0 > pointBound){
        if(macd_h_1 < pointBound){
            //golden cross
            return(3);
        }
        else{
            if(macd_h_0 > macd_h_1){
                return(2);
            }
            else{
                //下降トレンド
                return(1);            
            }
        }
    }
    else if(macd_h_0 < (pointBound * -1)){
        if(macd_h_1 > (pointBound * -1)){
            //dead cross
            return(-3);
        }
        else{
            if(macd_h_0 < macd_h_1){
                return(-2);
            }
            else{
                //上昇トレンド
                return(-1);            
            }
        }
    }
    
    //other
    return(0);
}

int CheckCCI2(int timeframe,int fast,int shift,double bound, int applied_price)
{
    double cci_1=iCCI(NULL,timeframe,fast,applied_price,shift);
    double cci_2=iCCI(NULL,timeframe,fast,applied_price,shift+1);
    
    if(cci_1 > bound){
        if(cci_2 < bound){
            //golden cross
            return(3);
        }
        else{
            return(2);        
        }
    }
    else if(cci_1 < (bound * -1)){
        if(cci_2 > (bound * -1)){
            //dead cross
            return(-3);
        }
        else{
            return(-2);        
        }
    }
    
    return(0);
}

////////////////////
//OP_BUY	0
//OP_SELL	1
//OP_BUYLIMIT	2
//OP_SELLLIMIT	3
//OP_BUYSTOP	4
//OP_SELLSTOP	5
////////////////////
int GetTicketInfo(int magicNumber,int maxCnt,int &ticketCnt,int &posCmt,int &posCntBuy,int &posCntSell,int &ordCnt){

    int cmd;
    int i=0;
    int j=0;
    for(i = OrdersTotal()-1; i >= 0; i-- ){
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false){
            return(false);
        }
        for(j=0; j < maxCnt; j++){
            if(OrderSymbol() == Symbol() && OrderMagicNumber()==(magicNumber+j)){
                cmd=OrderType();
                if(cmd == 0 || cmd == 1 || cmd == 2 || cmd == 3 || cmd == 4 || cmd == 5){
                    ticketCnt++;
                }
                if(cmd == 0 || cmd == 1){
                    posCmt++;
                }
                if(cmd == 0){
                    posCntBuy++;
                }
                if(cmd == 1){
                    posCntSell++;
                }
                if(cmd == 2 || cmd == 3 || cmd == 4 || cmd == 5){
                    ordCnt++;
                }                
            }
        }
    }
    return(0);
}

int GetOrderOpenTime2(int magicNumber,int divMinute, int divMode){

    int diffSecond;
    int divSecond=divMinute * 60;

    for(int i = OrdersTotal()-1; i >= 0; i-- ){
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false){
            return(false);
        }
        for(int j=0; j < maxCnt; j++){
            if(OrderSymbol() == Symbol() && OrderMagicNumber()==(magicNumber+j)){
                //Otherwise, it will not be converted to seconds!
                if(divMode==1){
                    diffSecond=TimeCurrent()-OrderOpenTime();
                }
                else{
                    diffSecond=TimeCurrent()-OrderCloseTime();
                }

                if(diffSecond < divSecond){
                    //Print("trade off!");
                    return(-1);
                }
            }
        }
    }
    return(0);
}

int CheckTradeOffTime(int ordCnt){
    int i;
    ServerDateTime = TimeCurrent();
    ServerWeek=TimeDayOfWeek(ServerDateTime);    
    ServerHour=TimeHour(ServerDateTime);
    int gmto = GetGMTOffset();
    ServerHourGMT=ServerHour - gmto;
    if(displayMode==1){
        CommentEX(StringConcatenate("gmto=",gmto));
    }

    ServerMinute=TimeMinute(ServerDateTime);
    
    if(FridayTejimaiMode==1){
        if(ServerWeek==5 && ServerHourGMT==FridayTejimaiHourGMT){
            for(i=0; i < maxCnt; i++) {
                TicketClose2(0, magic + i);
            }
        }
    }

    if((ServerHourGMT < EntryStartHourGMT) || (ServerHourGMT >= EntryEndHourGMT)){
        if(ordCnt > 0){
            for(i=0; i < maxCnt; i++) {
                OrderCancel(-1, magic + i);
            }
            for(i=0; i < maxCnt; i++) {
                OrderCancel(1,  magic + i);
            }
        }
        return(1);
    }
        
    if(ServerWeek==6 || ServerWeek==0){
        return(1);
    }
    //   
    if(MondayTRADEOFF==1 && ServerWeek==1){
        return(1);
    }
    else if(TuesdayTRADEOFF==1 && ServerWeek==2){
        return(1);
    }
    else if(WednesdayTRADEOFF==1 && ServerWeek==3){
        return(1);
    }
    else if(ThursdayTRADEOFF==1 && ServerWeek==4){
        return(1);
    }        
    else if(FridayTRADEOFF==1 && ServerWeek==5){
        return(1);
    }
    
    if(NewYearTRADEOFF==1){
        if((Month() == 12 && Day() > 24) || (Month() == 1 && Day() < 8)){
            return(1);
        }
    }
    
    return(0);
}

int TicketClose2(int mode,int magicNumber)
{ 
    int total=OrdersTotal();
    double stoploss;
    
    for(int i=total-1; i>=0; i--){
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ==false){
            continue;
        }
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == magicNumber){
            if(mode == 1 || mode == 0){
                if(OrderType() == OP_BUY){
                    if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),3,Green) != TRUE){
                        Print("LastError = ", ErrorDescription(GetLastError()));
                    }
                    return(0);
                }
                else if(OrderType() == OP_BUYLIMIT || OrderType() == OP_BUYSTOP){
                    if( OrderDelete(OrderTicket()) !=TRUE ){
                        Print("LastError = ", ErrorDescription(GetLastError()));
                    }
                    return(0);
                }
            }
            if(mode == -1 || mode == 0){
                if(OrderType() == OP_SELL){
                    if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),3,Green) != TRUE){
                        Print("LastError = ", ErrorDescription(GetLastError()));
                    }
                    return(0);
                }
                else if(OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP){
                    if( OrderDelete(OrderTicket()) !=TRUE ){
                        Print("LastError = ", ErrorDescription(GetLastError()));
                    }
                    return(0);
                }
            }
        }
    }
    return(0);
}

int OrderCancel(int mode,int magicNumber)
{
    int total=OrdersTotal();

    for(int i=total-1; i>=0; i--){
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ==false){
            continue;
        }
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == magicNumber){
            if(mode == 1){
                if(OrderType() ==  2 || OrderType() == 4){
                    if( OrderDelete(OrderTicket()) !=TRUE ){
                        //Print("LastError = ", ErrorDescription(GetLastError()));
                    }
                    return(0);
                }
            }
            else if(mode == -1){
                if(OrderType() == 3 || OrderType() == 5){
                    if( OrderDelete(OrderTicket()) !=TRUE ){
                        //Print("LastError = ", ErrorDescription(GetLastError()));
                    }
                    return(0);
                }
            }
        }
    }
    return(0);
}

void CommentEX(string msg = "")
{
   static string msgall = "";
   if(msg ==""){
      msgall= "";
   }else{
      msgall = msgall + "\n\r" + "" + msg;
   }
   Comment(msgall);
   //Print(msg);
   return;
}

int GetGMTOffset()
{
    if(IsTesting()){
        return(TestGMTOffset);
    }
    MqlDateTime current;
    MqlDateTime gmt;
    int offset = 0;
    
    TimeCurrent(current);
    TimeGMT(gmt);
    if((current.day - gmt.day) > 0){
        offset =  24;
    }
    if((current.day - gmt.day) < 0){
        offset = -24;
    }
 
    return(current.hour - gmt.hour + offset);
}

double CheckStopLevelPrice(double openPrice ,bool type ){

  double stoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
  double p = MarketInfo(Symbol(),MODE_POINT);
  double StopLevelPrice;
  
  if(type==OP_BUY || type==OP_BUYLIMIT || type==OP_BUYSTOP){
    StopLevelPrice =Ask - (stoplevel * p);
    return (StopLevelPrice);
  }
  else{
    StopLevelPrice =Bid + (stoplevel * p);
    return (StopLevelPrice);
  }
  
  return(-1);
}

int CloseByMACD(int magicNumber,int pattern)
{
    if(pattern==1){
        if(isMACDSmall>=3){
            TicketClose2(-1, magicNumber);
        }
        else if(isMACDSmall<=-3){
            TicketClose2(1, magicNumber);
        }
    }                
    else if(pattern==2){
        if(isMACDMiddle>=3){
            TicketClose2(-1, magicNumber);
        }
        else if(isMACDMiddle<=-3){            
            TicketClose2(1, magicNumber);
        }
    }       
    else if(pattern==3){
        if(isMACDLarge>=3){
            TicketClose2(-1, magicNumber);
        }
        else if(isMACDLarge<=-3){            
            TicketClose2(1, magicNumber);
        }
    }
    else if(pattern==4){
        if(isMACDSmall>=3){
            TicketClose2(1, magicNumber);
        }
        else if(isMACDSmall<=-3){
            TicketClose2(-1, magicNumber);
        }
    }                
    else if(pattern==5){
        if(isMACDMiddle>=3){
            TicketClose2(1, magicNumber);
        }
        else if(isMACDMiddle<=-3){            
            TicketClose2(-1, magicNumber);
        }
    }       
    else if(pattern==6){
        if(isMACDLarge>=3){
            TicketClose2(1, magicNumber);
        }
        else if(isMACDLarge<=-3){            
            TicketClose2(-1, magicNumber);
        }
    }
    
    return(0);
}

bool CheckCandleLength(int timeframe,int shift,double squeeze)
{
    double open_n = iOpen(NULL,timeframe,shift);
    double close_n = iClose(NULL,timeframe,shift);
    
    if(close_n > open_n){
        if(close_n-open_n > squeeze*pointPerPips){
            return false;
        }
    }
    else if(close_n < open_n){
        if(open_n-close_n > squeeze*pointPerPips){
            return false;
        }
    }

    return(true);
}

bool isClosed(int magic){
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--){
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) return(false);
      if(OrderMagicNumber() != magic) continue;
      if(OrderSymbol() != Symbol()) continue;
      
      if(Time[0] <= OrderCloseTime()){
         return(true);
      }
   }
   return(false);
}

bool EnableCheck(){

    if(IsDemo() == false){
       Print("Demo Account Only 1");
       return(false);
    }    
    if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL){
       Print("Demo Account Only 2");
       return false;
    }
    return true;
}

int SetFundTest(int &entry)
{
    if(FUNDA==1 && entry==-1){
        entry=0;
    }
    else if(FUNDA==-1 && entry==1){
        entry=0;   
    }
    return(0);
}

int SetFund(int &entry)
{
    if(FUNDA==1 && entry==-1){
        entry=0;
    }
    else if(FUNDA==-1 && entry==1){
        entry=0;   
    }
    return(0);
}
