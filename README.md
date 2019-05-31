# MetaTrading
Basic algorithm written in MQL4 to trade on the forex

This is not a working algorithm. I am working on cleaning up other algorithms so it is
clear what is involved in the process of writing an automated algorithm. Still need to 
implement features to open a position, choose position size and determine an exit 
position. There is also the option to either exit the position at a predetermined price
or trail the price. So, there should be an algorithm that trails the price.

Just need to find the time to do this in a way that it's as clear as possible.


For your consideration, 

When Trading
1. You need a strategy to tell you when to open a position and in which direction.
	-plug in whatever strategy you've come up with
2. You need a means of determining how much you're willing to lose if the strategy was wrong.
	-position size depends on % of balance risked and exit position
3. You need a strategy to determine when you will be exiting the position.
	-right now based on calculating the Average True Range (measure of price deviation)
4. That is all.
