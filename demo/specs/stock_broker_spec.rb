#require 'rubygems'
#require_gem 'rspec'
require 'spec'
$:.unshift('lib')
require 'stock_broker'




class StockBrokerSpec < Spec::Context
  
  def setup
    @market = mock("market")
    @broker = StockBroker.new(@market)
  end
  
  def should_bid_one_cheaper_when_price_above_50000
    @market.should_receive(:price_for).with("RUBY").and_return(50001)
    @market.should_receive(:bid) do |sym, price|
      sym.should_match /UR/
      price.should_equal 50000
    end
    
    result = @broker.deal("RUBY")
    result.should_be_nil
  end
end

















if __FILE__ == $0
  runner = Spec::TextRunner.new($stdout)
  runner.run(StockBrokerSpec)
end
