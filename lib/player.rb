require_relative 'hand'

class Player
  attr_accessor :wallet, :hand

  def initialize(starting_funds)
    @wallet = starting_funds
    @hand = Hand.new
  end

  def place_bet(amount)
    @wallet -= amount
    amount
  end

  def receive_winnings(amount)
    @wallet += amount
  end
end

