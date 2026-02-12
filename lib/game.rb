require_relative 'color'
require_relative 'deck'
require_relative 'player'
require_relative 'hand'
require_relative 'card'

class Game
  SAVE_FILE = "blackjack_data.json"

  def initialize
    @prompt = TTY::Prompt.new
    @deck = Deck.new
    data = load_data
    @player = Player.new(data[:wallet])
    @high_score = data[:high_score]
    @dealer_hand = Hand.new
  end

  def load_data
    if File.exist?(SAVE_FILE)
      data = JSON.parse(File.read(SAVE_FILE))
      { wallet: data["wallet"] || 1000, high_score: data["high_score"] || 0 }
    else
      {wallet: 1000, high_score: 0 }
    end
  rescue
    { wallet: 1000, high_score: 0 } # Default if file is corrupted
  end

  def save_data
    data =  {
      "wallet"=> @player.wallet,
      "high_score" => @high_score || 0
    }
    File.write(SAVE_FILE, JSON.generate(data))
  end

  def main_menu
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

      choices = [
        { name: "Start New Game", value: :new },
        { name: "Load Previous Game", value: :load},
        { name: "Show High Score", value: :high_score},
        { name: "Quit", value: :quit}
      ]

      action = @prompt.select("\nWelcome to the Casino!", choices)

      case action 
      when :new
        @player.wallet = 1000
        save_data
        play
      when :load
        play
      when :high_score
        puts "\n#{Color::YELLOW}Your High Score: $#{@high_score}#{Color::RESET}"
        @prompt.keypress("Press any key to return to menu...")
      when :quit
        break
      end
    end
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
        save_data
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

      save_data
      break unless @prompt.yes?("\nPlay another round?")
    end

    clear_screen
    save_data
    puts "\nThanks for playing! Final wallet: #{Color::GREEN}#{Color::BOLD}$#{@player.wallet}#{Color::RESET}"
    draw_line
  end

  private

  def player_turn
    can_double = @player.hand.cards.length == 2 && @player.wallet >= @current_bet
    loop do 

      choices = { "Hit" => :hit, "Stay" => :stay }
      choices["Double Down"] = :double if can_double

      action = @prompt.select("\nWhat would you like to do?", choices)

      if action == :hit
        can_double = false
        @player.hand.add_card(@deck.deal)
        puts "Your hand:   #{@player.hand}"
        draw_line

        if @player.hand.value > 21
          break
        end
      elsif action == :stay
        break

      elsif action == :double
        @player.place_bet(@current_bet)
        @current_bet *= 2
        puts "\n#{Color::YELLOW}Bet increased to $#{@current_bet}!#{Color::RESET}"

        @player.hand.add_card(@deck.deal)
        puts "Your hand:    #{@player.hand}"

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
    if @player.wallet > @high_score
      @high_score = @player.wallet
      puts "#{Color::BOLD}New High Score!#{Color::RESET}"
      save_data
    end
    draw_line
  end
end

