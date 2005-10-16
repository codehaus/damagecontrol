$:.unshift('lib')
require 'spec'
require 'stock_broker'

class StockBrokerSpec < Spec::Context
  
  def setup
    @market = mock("market")
    @broker = StockBroker.new(@market)
  end
  
  def should_bid_when_price_below_45_and_return_true
    @market.should_receive(:quote).with("RUBY").and_return(45)
    @market.should_receive(:bid).with("RUBY", 45)    
    result = @broker.trade("RUBY")
    result.should_be_true
  end

  def should_not_bid_when_price_above_45_and_return_false
    @market.should_receive(:quote).with("RUBY").and_return(46)
    result = @broker.trade("RUBY")
    result.should_be_false
  end
end

















if __FILE__ == $0
  runner = Spec::TextRunner.new($stdout)
  runner.run(StockBrokerSpec)
end
