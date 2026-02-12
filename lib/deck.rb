require_relative 'color'
require_relative 'card'

class Deck
  def initialize
    @cards = []
    # Using 6 decks for a "Casino Shoe" feel
    6.times do
      suits = ["♠", "♥", "♦", "♣"]
      ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, "Jack", "Queen", "King", "Ace"]

      suits.each do |suit|
        ranks.each do |rank|
          @cards << Card.new(suit, rank)
        end
      end
    end

    @cards.shuffle!
  end

  def deal
    @cards.pop
  end
end


