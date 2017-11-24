//+------------------------------------------------------------------+
//|                                                        Trend.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"



static int MaxOrders=4;
extern double MaxRisk=1;//资金风险1=1%
static int STO_PERIOD_M15= 8;
static int STO_PERIOD_H1 = 5;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum STATE 
  {
   BULL,
   BEAR,
   SWING
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotsOptimized(double RiskValue)
  {
//最大可开仓手数  ？最好用净值 不要用余额
   double iLots=NormalizeDouble((AccountBalance()*RiskValue/100/MarketInfo(Symbol(),MODE_MARGINREQUIRED)),2);

   if(iLots<0.01)
     {
      iLots=0;
      Print("保证金余额不足");
     }

   return iLots;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/**
   获取不同货币对止损(短线交易)
 */
int getStopLoss_s(string symbol)
  {
   int stopLoss=15;
   if(symbol=="GBPUSD" || symbol=="USDCAD") 
     {
      stopLoss=20;
     }

   return stopLoss;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/**
   获取不同货币对止损(短线交易)
 */
int getTakeProfit_s(string symbol)
  {
   int stopLoss=15;
   if(symbol=="GBPUSD" || symbol=="USDCAD") 
     {
      stopLoss=20;
     }

   return stopLoss;
  }




/**
 *  返回值 :
 *      -1 - 下单失败 0 - 订单已存在 其它 - 订单号 
 */
int iOpenOrders(string myType,double myLots,int myLossStop,int myTakeProfit, string comment)
  {

   // 检查相同货币对是否已经下单
   bool isOrderOpen=false;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if((OrderComment()==comment))
           {
               isOrderOpen = true;
               return 0;
           }
        }
     }
   
   
   
   int ticketNo=-1;
   int mySpread=MarketInfo(Symbol(),MODE_SPREAD);//点差 手续费 市场滑点
   double sl_buy=(myLossStop<=0)?0:(Ask-myLossStop*Point);
   double tp_buy=(myTakeProfit<=0)?0:(Ask+myTakeProfit*Point);
   double sl_sell=(myLossStop<=0)?0:(Bid+myLossStop*Point);
   double tp_sell=(myTakeProfit<=0)?0:(Bid-myTakeProfit*Point);

   if(myType=="Buy")
      ticketNo=OrderSend(Symbol(),OP_BUY,myLots,Ask,mySpread,sl_buy,tp_buy, comment);
   if(myType=="Sell")
      ticketNo=OrderSend(Symbol(),OP_SELL,myLots,Bid,mySpread,sl_sell,tp_sell, comment);

   return ticketNo;
  }
  
  
/**
 * 平仓 关闭指定货币对订单
 */
void iCloseOrder(string symbol) {
   
   int cnt=OrdersTotal();
   
   if(OrderSelect(cnt-1,SELECT_BY_POS)==false)
      return;
   
   for(int i = cnt - 1; i >= 0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderComment() == symbol) {
            OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0);
         }
      }
   }
   
}

/**
 * 查询当前货币对订单数
 */

int getOrderCount(string symbol) {
   int total = 0;
   
   int cnt=OrdersTotal();
   
   if(OrderSelect(cnt-1,SELECT_BY_POS)==false)
      return total;
   
   for(int i = cnt - 1; i >= 0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if(OrderSymbol() == symbol) {
            total ++;
         }
      }
   }
   
   return total;
   
}
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void iCloseOrders(string myType)
  {
   int cnt=OrdersTotal();
   int i;
//选择当前持仓单
   if(OrderSelect(cnt-1,SELECT_BY_POS)==false)return;
   if(myType=="All")
     {
      for(i=cnt-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)==false)continue;
         else OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0); //? Close[0]与OrderClosePrice()有区别么
        }
     }
   else if(myType=="Buy")
     {
      for(i=cnt-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)==false)continue;
         else if(OrderType()==OP_BUY) OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0);
        }
     }
   else if(myType=="Sell")
     {
      for(i=cnt-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)==false)continue;
         else if(OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0);
        }
     }
   else if(myType=="Profit")
     {
      for(i=cnt-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)==false)continue;
         else if(OrderProfit()>0) OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0);
        }
     }
   else if(myType=="Loss")
     {
      for(i=cnt-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)==false)continue;
         else if(OrderProfit()<0) OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0);
        }
     }
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   // 已经达到最大订单数
   if(OrdersTotal()>=MaxOrders) 
     {
      return;
     }
     
   if(getOrderCount(Symbol()) >= 1) {
      return;
   }
   
   bool isTrendChanged = isTrendChange(1,2);
   
   



  }
  
  
STATE getTrend(int index) {
   STATE state = SWING;
   
   
   double MA10=iMA(Symbol(),0,10,0,MODE_EMA,PRICE_CLOSE,index);
   double MA20=iMA(Symbol(),0,20,0,MODE_EMA,PRICE_CLOSE,index);


   // 计算基准线Kijun-sen
   double kijunsen=iIchimoku(Symbol(),0,7,22,44,MODE_KIJUNSEN,index);
   double tenkansen=iIchimoku(Symbol(),0,7,22,44,MODE_TENKANSEN,index);
   
   double close=iClose(Symbol(),0,index);
   
   if(close>=kijunsen && tenkansen>=kijunsen) 
     {
      if(close>MA10 && close>MA20) 
        {
         state=BULL;
        }
        } else if(close<kijunsen && tenkansen<kijunsen) {
      if(close<MA10 && close<MA20) 
        {
         state=BEAR;
        }
        } else {
      state=SWING;
     }
     
     
   return state;
}


//+------------------------------------------------------------------+

bool isTrendChange(int cur,int prev) 
  {

   STATE curState=SWING;
   STATE prevState=SWING;

   double MA10=iMA(Symbol(),0,10,0,MODE_EMA,PRICE_CLOSE,cur);
   double prevMA10=iMA(Symbol(),0,10,0,MODE_EMA,PRICE_CLOSE,prev);
   double MA20=iMA(Symbol(),0,20,0,MODE_EMA,PRICE_CLOSE,cur);
   double prevMA20=iMA(Symbol(),0,20,0,MODE_EMA,PRICE_CLOSE,prev);

// 计算基准线Kijun-sen
   double kijunsen=iIchimoku(Symbol(),0,7,22,44,MODE_KIJUNSEN,cur);
   double prevKijunsen=iIchimoku(Symbol(),0,7,22,44,MODE_KIJUNSEN,prev);
   double tenkansen=iIchimoku(Symbol(),0,7,22,44,MODE_TENKANSEN,cur);
   double prevTenkansen=iIchimoku(Symbol(),0,7,22,44,MODE_TENKANSEN,prev);

   double close=iClose(Symbol(),0,cur);
   double prevClose=iClose(Symbol(),0,prev);

   if(close>=kijunsen && tenkansen>=kijunsen) 
     {
      if(close>MA10 && close>MA20) 
        {
         curState=BULL;
        }
        } else if(close<kijunsen && tenkansen<kijunsen) {
      if(close<MA10 && close<MA20) 
        {
         curState=BEAR;
        }
        } else {
      curState=SWING;
     }

   if(prevClose>=prevKijunsen && prevTenkansen>=prevKijunsen) 
     {
      if(prevClose>prevMA10 && prevClose>prevMA20) 
        {
         prevState=BULL;
        }
        }else if(prevClose<prevKijunsen && prevTenkansen<prevKijunsen) {
      if(prevClose<prevMA10 && prevClose<prevMA20) 
        {
         prevState=BEAR;
        }
        } else {
      prevState=SWING;
     }

   if(curState!=prevState) 
     {
      return true;
     }

   return false;

  }
//+------------------------------------------------------------------+
