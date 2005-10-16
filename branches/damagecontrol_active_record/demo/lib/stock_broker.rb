class StockBroker
  def initialize(market)
    @market = market
  end
  
  def trade(sym)
    price = @market.quote(sym)
    if(price <= 45)
      @market.bid(sym, price)
      true
    else
      false
    end
  end
end