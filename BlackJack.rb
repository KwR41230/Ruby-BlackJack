module Color
  RED = "\e[31m"
  GREEN = "\e[32m"
  YELLOW = "\e[33m"
  BLUE = "\e[34m"
  BOLD = "\e[1m"
  RESET = "\e[0m"
end

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

class Game
  def initialize
    @deck = Deck.new
    @player = Player.new(1000)
    @dealer_hand = Hand.new
  end

  def clear_screen
    system("clear") || system("cls")
  end

  def draw_line
    puts "#{Color::BLUE}-#{Color::RESET}" * 40
  end

  def draw_star
    puts "#{Color::BOLD}#{Color::BLUE}*#{Color::RESET}" * 60
  end

  def play
    loop do
      clear_screen
      draw_star
      puts <<~'HEREDOC'
          _ _ _ ____ _    ____ ____ _  _ ____    ___ ____
          | | | |___ |    |    |  | |\/| |___     |  |  | 
          |_|_| |___ |___ |___ |__| |  | |___     |  |__|

              ,-,---. .              ,-_/                    
               '|___/ |  ,-. ,-. . , '  | ,-. ,-. . ,        
      -- -- -- ,|   \ |  ,-| |   |/     | ,-| |   |/ -- -- --
              `-^---' `' `-^ `-' |\     | `-^ `-' |\         
                                     `--'                    
      HEREDOC
      draw_star

      @deck = Deck.new if @deck.nil? # Keep the shoe unless it's empty
      @player.hand = Hand.new
      @dealer_hand = Hand.new

      puts "\n#{Color::BOLD}#{Color::GREEN}Current Wallet: $#{@player.wallet}#{Color::RESET}"
      
      if @player.wallet <= 0
        puts "\n#{Color::RED}You're out of money! Game Over.#{Color::RESET}"
        break
      end

      print "\nHow much do you want to bet? (or (q)uit): "
      input = gets.chomp
      break if input.downcase == 'q'
      
      @current_bet = input.to_i
      if @current_bet <= 0 || @current_bet > @player.wallet
        puts "#{Color::RED}Invalid bet.#{Color::RESET}"
        sleep(1)
        next
      end

      @player.place_bet(@current_bet)

      2.times do 
        @player.hand.add_card(@deck.deal)
        @dealer_hand.add_card(@deck.deal)
      end

      puts "\nDealer shows: #{@dealer_hand.cards.first}"
      draw_line
      puts "Your hand:   #{@player.hand}"
      draw_line
      
      # Instant Blackjack Check
      if @player.hand.blackjack?
        determine_winner
      else
        player_turn
        if @player.hand.value <= 21
          dealer_turn
          determine_winner
        else
          puts "\n#{Color::RED}#{Color::BOLD}Bust! You lose.#{Color::RESET}"
        end
      end

      print "\nPlay another round? (y/n): "
      break if gets.chomp.downcase != 'y'
    end

    clear_screen
    puts "\nThanks for playing! Final wallet: #{Color::GREEN}#{Color::BOLD}$#{@player.wallet}#{Color::RESET}"
    draw_line
  end

  private

  def player_turn
    while @player.hand.value < 21
      print "\nDo you want to #{Color::BOLD}(h)it#{Color::RESET} or #{Color::BOLD}(s)tay#{Color::RESET}? "
      input = gets.chomp.downcase

      if input == "h"
        @player.hand.add_card(@deck.deal)
        puts "Your hand:   #{@player.hand}"
        draw_line
      elsif input == "s"
        break
      end
    end
  end

  def dealer_turn
    puts "\nDealer's hand: #{@dealer_hand}"
    while @dealer_hand.value < 17
      print "#{Color::YELLOW}Dealer thinking"
      3.times do
        print "."
        sleep(0.4)
      end
      print "#{Color::RESET}\n"
      
      @dealer_hand.add_card(@deck.deal)
      puts "Dealer hits and gets: #{@dealer_hand.cards.last}"
      puts "Dealer's hand: #{@dealer_hand}"
      draw_line
    end
  end

  def determine_winner
    player_total = @player.hand.value
    dealer_total = @dealer_hand.value

    puts "\n#{Color::BOLD}--- Final Score ---#{Color::RESET}"
    puts "You:    #{player_total}"
    puts "Dealer: #{dealer_total}"

    if @player.hand.blackjack? && !@dealer_hand.blackjack?
      winnings = (@current_bet * 2.5).to_i
      puts "\n#{Color::YELLOW}#{Color::BOLD}BLACKJACK! ♠️ Payout: +$#{(@current_bet * 1.5).to_i}#{Color::RESET}"
      @player.receive_winnings(winnings)
    elsif dealer_total > 21 || player_total > dealer_total
      puts "\n#{Color::GREEN}#{Color::BOLD}YOU WIN! +$#{@current_bet}#{Color::RESET}"
      @player.receive_winnings(@current_bet * 2)
    elsif player_total < dealer_total
      puts "\n#{Color::RED}#{Color::BOLD}DEALER WINS! -$#{@current_bet}#{Color::RESET}"
    else
      puts "\n#{Color::YELLOW}#{Color::BOLD}PUSH (TIE)#{Color::RESET}"
      @player.receive_winnings(@current_bet)
    end
    draw_line
  end
end

Game.new.play