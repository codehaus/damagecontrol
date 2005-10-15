class StockBroker
  def initialize(market)
    @market = market
  end
  
  def deal(sym)
    price = @market.price_for(sym)
    @market.bid(sym, price-1)
  end
end