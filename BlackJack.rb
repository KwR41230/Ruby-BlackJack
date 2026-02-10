require 'tty-prompt'
require 'json'

require 'tty-prompt'
require 'json'

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
  SAVE_FILE = "blackjack_data.json"

  def initialize
    @prompt = TTY::Prompt.new
    @deck = Deck.new
    @player = Player.new(load_wallet)
    @dealer_hand = Hand.new
  end

  def load_wallet
    if File.exist?(SAVE_FILE)
      data = JSON.parse(File.read(SAVE_FILE))
      data["wallet"] || 1000
    else
      1000
    end
  rescue
    1000 # Default if file is corrupted
  end

  def save_wallet
    File.write(SAVE_FILE, JSON.generate({ "wallet" => @player.wallet }))
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
        puts "\n#{Color::RED}You're out of money! Resetting to $1000.#{Color::RESET}"
        @player.wallet = 1000
        save_wallet
        sleep(2)
      end

      @current_bet = @prompt.ask("\nHow much do you want to bet? (or 0 to quit):", default: 10) do |q|
        q.validate ->(input) { input.to_i >= 0 && input.to_i <= @player.wallet }
        q.messages[:valid?] = "Invalid bet! Must be between 0 and #{@player.wallet}."
        q.convert :int
      end

      break if @current_bet == 0

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

      save_wallet
      break unless @prompt.yes?("\nPlay another round?")
    end

    clear_screen
    save_wallet
    puts "\nThanks for playing! Final wallet: #{Color::GREEN}#{Color::BOLD}$#{@player.wallet}#{Color::RESET}"
    draw_line
  end

  private

  def player_turn
    while @player.hand.value < 21
      choices = { "Hit" => :hit, "Stay" => :stay }
      action = @prompt.select("\nWhat would you like to do?", choices)

      if action == :hit
        @player.hand.add_card(@deck.deal)
        puts "Your hand:   #{@player.hand}"
        draw_line
      elsif action == :stay
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
