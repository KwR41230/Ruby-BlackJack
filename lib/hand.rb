require_relative 'color'
require_relative 'card'

class Hand
  attr_reader :cards

  def initialize
    @cards = []
  end

  def add_card(card)
    @cards << card
  end

  def value
    total = 0
    aces = 0

    @cards.each do |card|
      if card.rank == "Ace"
        aces += 1
        total += 11
      elsif ["Jack", "Queen", "King"].include?(card.rank)
        total += 10
      else
        total += card.rank.to_i
      end
    end

    while total > 21 && aces > 0
      total -= 10
      aces -= 1
    end

    total
  end

  def blackjack?
    @cards.length == 2 && value == 21
  end

  def to_s
    @cards.map(&:to_s).join(", ") + " #{Color::YELLOW}(Total: #{value})#{Color::RESET}"
  end
end


