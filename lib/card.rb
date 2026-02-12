require_relative 'color'

class Card
  attr_reader :suit, :rank

  def initialize(suit, rank)
    @suit = suit
    @rank = rank
  end

  def color
    if suit == "♥" || suit == "♦"
      Color::RED
    elsif suit == "♠" || suit == "♣"
      Color::GREEN
    else
      Color::RESET
    end
  end

  def to_s
    "#{color}#{rank} #{suit} #{Color::RESET}"
  end
end


