require 'faraday'
require 'json'
require 'digest/md5'

BASE_API_URL = 'https://webapi.asianodds88.com/AsianOddsService'

module Asianodds
  class Login

    attr_reader :code, :ao_token, :ao_key, :base_url, :successful_login, :message

    # The API has a very standard request format for get requests - Use this one to stay DRY
    def get_request(route)
      response = Faraday.get "#{@base_url}/#{route}", {}, {
        'Accept': 'application/json',
        'AOToken': @ao_token,
        'AOKey': @ao_key
      }
      return JSON.parse(response.body, :symbolize_names => true)
    end

    # The API has a very standard request format for post requests - Use this one to stay DRY
    def post_request(route, body)
      response = Faraday.post "#{@base_url}/#{route}",
      body,
      {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'AOToken': @ao_token
      }

      return JSON.parse(response.body, :symbolize_names => true)
    end

    # Initialize the user with a username and password, as well as hashed password as requested from AO
    def initialize(user, password)
      @user = user
      @password = password
      @password_md5 = Digest::MD5.hexdigest(@password)
      @ao_token = 'default'
      @ao_key = 'default'
      @base_url = BASE_API_URL
      login
    end

    # Log the user in to receive a token and key
    def login
      response = get_request("Login?username=#{@user}&password=#{@password_md5}")
      @code = response[:Code]
      @ao_token = response[:Result][:Token]
      @ao_key = response[:Result][:Key]
      @base_url = response[:Result][:Url]
      @successful_login = response[:Result][:SuccessfulLogin]

      # All logged in users need to be registered with a token and key
      if @successful_login
        @message = "You successfully logged in - registering..."
        register
      else
        @message = response[:Result][:TextMessage]
      end
    end

    # With the token and key the user has to be registered
    def register
      response = get_request("Register?username=#{@user}")
      response[:Result][:Success] == true ? @message = response[:Result][:TextMessage] : @message = "Registration failed"
    end

    # Before executing any request which requires a logged in user (all), check for login
    # Check for all following requests whether user is logged in and if not, log her in
    def loggedin?
      if @ao_token
        response = get_request('IsLoggedIn')
        return response[:Result][:CurrentlyLoggedIn] ? true : false
      else
        return false
      end
    end

    # Log the user out. In order for this to work, the user must be logged in
    def logout
      response = get_request('Logout')
      return response[:Result]
    end

    # Get all the Match Feeds (odds, status, etc.) based on the settings provided
    def get_feeds(attributes)
      attributes[:sports_type].nil? ? sports_type = 1 : sports_type = attributes[:sports_type]
      attributes[:market_type].nil? ? market_type = 1 : market_type = attributes[:market_type]
      attributes[:bookies].nil? ? bookies = 'ALL' : bookies = attributes[:bookies]
      attributes[:leagues].nil? ? leagues = 'ALL' : leagues = attributes[:leagues]
      attributes[:odds_format].nil? ? odds_format = '00' : odds_format = attributes[:odds_format]
      attributes[:since].nil? ? since = '0' : since = attributes[:since]

      if loggedin?
        return get_request("GetFeeds?sportsType=#{sports_type}&marketTypeId=#{market_type}&bookies=#{bookies}&leagues=#{leagues}&oddsFormat=#{odds_format}&since=#{since}")
      else
        #raise NotLoggedIn
      end
    end

    # Get all active bets (= running, outstanding, finished) of the current user
    def get_bets
      if loggedin?
        return get_request('GetBets')
      else
        #raise NotLoggedIn
      end
    end

    # You can also request a single bet with its reference - useful to check whether the bet was accepted by the bookmaker
    def get_bet_by_reference(bet_reference)
      if loggedin?
        return get_request("GetBetByReference?betReference=#{bet_reference}")
      else
        #raise NotLoggedIn
      end
    end

    # A subset of GetBets which returns only the currently running bets
    def get_running_bets
      if loggedin?
        return get_request('GetRunningBets')
      else
        #raise NotLoggedIn
      end
    end

    # A subset of GetBets which returns only the currently not running bets
    def get_non_running_bets
      if loggedin?
        return get_request('GetNonRunningBets')
      else
        #raise NotLoggedIn
      end
    end

    # Get the users account summary (i.e. users currency, users credit, outstanding amount, P&L's etc.)
    def get_account_summary
      if loggedin?
        return get_request('GetAccountSummary')
      else
        #raise NotLoggedIn
      end
    end

    # Get a transaction history of a certain time-frame - defaults to the last 7 days
    def get_history_statement(attributes)
      attributes[:from_date].nil? ? from_date = (Date.today - 7).strftime('%m/%d/%Y') : from_date = attributes[:from_date]
      attributes[:to_date].nil? ? to_date = Date.today.strftime('%m/%d/%Y') : to_date = attributes[:to_date]
      attributes[:bookies].nil? ? bookies = 'ALL' : bookies = attributes[:bookies]
      if loggedin?
        return get_request("GetHistoryStatement?from=#{from_date}&to=#{to_date}&bookies=#{bookies}&shouldHideTransactionData=false")
      else
        #raise NotLoggedIn
      end
    end

    # Get the list of bookmakers available on the Asianodds platform
    def get_bookies
      if loggedin?
        return get_request('GetBookies')
      else
        #raise NotLoggedIn
      end
    end

    # Get user setting, such as account status, ip address, username etc.
    def get_user_information
      if loggedin?
        return get_request('GetUserInformation')
      else
        #raise NotLoggedIn
      end
    end

    # Get all the transactions of a specific day (defaults to yesterday) including win and loss values
    def get_bet_history_summary(attributes)
      attributes[:date].nil? ? date = (Date.today - 1).strftime('%m/%d/%Y') : date = attributes[:date]
      attributes[:bookies].nil? ? bookies = 'ALL' : bookies = attributes[:bookies]
      if loggedin?
        return get_request("GetBetHistorySummary?date=#{date}&bookies=#{bookies}")
      else
        #raise NotLoggedIn
      end
    end

    # Get the ids for all leagues for a certain sport (football as default)
    def get_leagues(attributes)
      attributes[:sports_type].nil? ? sports_type = 1 : sports_type = attributes[:sports_type]
      attributes[:market_type].nil? ? market_type = 1 : market_type = attributes[:market_type]
      attributes[:bookies].nil? ? bookies = 'ALL' : bookies = attributes[:bookies]
      attributes[:since].nil? ? since = '0' : since = attributes[:since]
      if loggedin?
        return get_request("GetLeagues?sportsType=#{sports_type}&marketTypeId=#{market_type}&bookies=#{bookies}&since=#{since}")
      else
        #raise NotLoggedIn
      end
    end

    # Get the ids for the sports offered by Asianodds (football and basketball as of today)
    def get_sports
      if loggedin?
        return get_request('GetSports')
      else
        #raise NotLoggedIn
      end
    end

    # Get all the Matches (!= feeds) based on the settings provided
    def get_matches(attributes)
      attributes[:sports_type].nil? ? sports_type = 1 : sports_type = attributes[:sports_type]
      attributes[:market_type].nil? ? market_type = 1 : market_type = attributes[:market_type]
      attributes[:bookies].nil? ? bookies = 'ALL' : bookies = attributes[:bookies]
      attributes[:leagues].nil? ? leagues = 'ALL' : leagues = attributes[:leagues]
      attributes[:since].nil? ? since = '0' : since = attributes[:since]

      if loggedin?
        return get_request("GetMatches?sportsType=#{sports_type}&marketTypeId=#{market_type}&bookies=#{bookies}&leagues=#{leagues}&since=#{since}")
      else
        #raise NotLoggedIn
      end
    end

    # Get information about the odds, minimum and maximum amounts to bet etc. for a certain match
    # THIS IS A POST REQUEST
    def get_placement_info(attributes)
      body = {
        "GameId": attributes[:game_id],
        "GameType": attributes[:game_type],
        "IsFullTime": attributes[:is_full_time],
        "Bookies": attributes[:bookies],
        "MarketTypeId": attributes[:market_type],
        "OddsFormat": attributes[:odds_format],
        "OddsName": attributes[:odds_name],
        "SportsType": attributes[:sports_type]
      }.to_json

      if loggedin?
        return post_request('GetPlacementInfo', body)
      else
        #raise NotLoggedIn
      end
    end

    # Get information about the odds, minimum and maximum amounts to bet etc. for a certain match
    # THIS IS A POST REQUEST
    def place_bet(attributes)
      body = {
        "GameId": attributes[:game_id],
        "GameType": attributes[:game_type],
        "IsFullTime": attributes[:is_full_time],
        "Bookies": attributes[:bookies],
        "MarketTypeId": attributes[:market_type],
        "OddsFormat": attributes[:odds_format],
        "OddsName": attributes[:odds_name],
        "SportsType": attributes[:sports_type],
        "BookieOdds": attributes[:bookie_odds],
        "Amount": attributes[:amount]
      }.to_json

      if loggedin?
        # Always needs to be called before placing the bet
        get_placement_info(attributes)
        return post_request('PlaceBet', body)
      else
        #raise NotLoggedIn
      end
    end


  end
end
