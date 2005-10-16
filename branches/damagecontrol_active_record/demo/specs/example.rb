# intent, example, scenario, behavior, sequence, result, story

fixture :foo do
  @market = mock("market")
  @broker = StockBroker.new(@market)
end

scenario "Broker bids when price <= 45", :setup => :foo do
  @market.should_receive(:quote).with("RUBY").and_return(45)
  @market.should_receive(:bid).with("RUBY", 45)

  result = @broker.trade("RUBY")
end
