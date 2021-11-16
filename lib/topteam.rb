# frozen_string_literal: true

require_relative "topteam/version"

module Topteam

  # Simple struct for keeping track of team name/score tuples
  TeamScore = Struct.new(:name, :score)

  # Associates a team name with a game history (consisting of 0, 1 or 3 points earned, for a loss, tie, or win, respectively).
  class Team
    attr_reader :name, :history

    def initialize(name)
      @name = name
      @history = []
    end

    def win!
      @history << 3
    end

    def loss!
      @history << 0
    end

    def tie!
      @history << 1
    end

    def matches_played
      @history.length
    end

    def score
      @history.sum
    end

    def score_after_match(match_num)
      @history[0...match_num].sum
    end
  end

  # Container class representing a game. Holds team names and game scores. Also provides parsing of game input.
  class Game
    attr_accessor :match_day
    attr_reader :team1, :team2

    def self.parse_game(game_string)
      team_scores = game_string.split(", ").map { |ts| parse_team_score(ts) }
      new(*team_scores)
    end

    def initialize(team1, team2)
      unless [team1, team2].all? { |t| t[0].is_a?(String) && t[1].is_a?(Integer) }
        raise ArgumentError, "arguments must be of form [string, integer], [string, integer]"
      end

      @team1 = TeamScore.new(team1[0], team1[1])
      @team2 = TeamScore.new(team2[0], team2[1])
    end

    def team_names
      [@team1.name, @team2.name]
    end

    def team_score_tuples
      [team1.to_a, team2.to_a]
    end

    def winner
      return if tie?

      [@team1, @team2].max_by(&:score).name
    end

    def tie?
      @team1.score == @team2.score
    end

    def self.parse_team_score(team_score_string)
      team_score_string.split(/\s(?=\d+$)/).tap do |array|
        array[1] = array[1].to_i
      end
    end

    private_class_method :parse_team_score
  end

  # Primary class. Contains teams, their score history, and method for ranking teams by match day
  class Season
    attr_reader :teams, :games
    attr_accessor :matches_per_day

    def initialize(games = [])
      @teams = []
      @games = []
      @rankings = []
      add_games(games)
    end

    # add teams to season if not already present
    def add_new_teams(team_names)
      new_teams = team_names.each_with_object([]) do |team_name, array|
        array << Topteam::Team.new(team_name) unless teams_hash.key?(team_name)
      end
      @teams += new_teams
    end

    def add_games(games)

      games.each_with_index do |game_string, idx|
        game = Topteam::Game.parse_game(game_string)

        add_new_teams(game.team_names) # add teams to season if not yet present

        # upon reoccurrence of team in next index in stream, set matches_per_day
        if !matches_per_day && games[idx + 1]
          next_game = Topteam::Game.parse_game(games[idx + 1])
          self.matches_per_day = (idx + 1) if (next_game.team_names & team_names).any?
        end

        case game.team1.score <=> game.team2.score
        when 1
          teams_hash[game.team1.name].win!
          teams_hash[game.team2.name].loss!
        when 0
          teams_hash[game.team1.name].tie!
          teams_hash[game.team2.name].tie!
        when -1
          teams_hash[game.team2.name].win!
          teams_hash[game.team1.name].loss!
        end
        @games << game

        # yield top three teams sorted by score, name
        yield(rankings.last[0..2], match_days) if end_of_match_day? && block_given?
      end
    end

    def end_of_match_day?
      return unless matches_per_day

      @teams.map(&:matches_played).uniq.length == 1
    end

    def match_days
      @teams.map(&:matches_played).uniq.min
    end

    # return array of standings, with each item representing a successive match day with the teams sorted by standing and name
    def rankings
      [].tap do |rankings_array|
        match_days.times do |i|
          rankings_array << @teams.map do |t|
            TeamScore.new(t.name, t.score_after_match(i + 1))
          end.sort_by { |t| [-t.score, -t.name] }
        end
      end
    end

    def teams_hash
      @teams.each_with_object({}) { |team, hash| hash[team.name] = team }
    end

    def teams_tuples
      @teams.map { |team| [team.name, team.score] }
    end

    def team_names
      @teams.map(&:name)
    end
  end
end
