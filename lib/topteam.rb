# frozen_string_literal: true

require_relative "topteam/version"

module Topteam
  class Error < StandardError; end

  class Team
    attr_reader :name
    attr_accessor :wins, :ties, :losses

    def initialize(name, wins: 0, losses: 0, ties: 0)
      @name = name
      @wins = wins
      @losses = losses
      @ties = ties
    end

    def win!
      @wins += 1
    end

    def loss!
      @losses += 1
    end

    def tie!
      @ties += 1
    end

    def score
      (3 * @wins) + @ties
    end
  end

  class Season
    def initialize
      @games = []
      @teams = []
    end

    def teams; end

    def match_days; end

    # TODO: consider overriding <<
    def add_game(game)
      game.match_day = @games.count { |g| game.teams_scores[0][0] == g } + 1
      @teams << game.team_1 unless @teams.any? { |team| team.name == game.team_1.name }
      @teams << game.team_2 unless @teams.any? { |team| team.name == game.team_2.name }
      @games << game
    end
  end

  class Game
    attr_accessor :match_day
    attr_reader :teams_scores

    def initialize(team1, team2)
      raise TypeError unless [team1, team2].all? { |t| t[0].is_a?(String) && t[1].is_a?(Integer) }

      @teams_scores = [team1, team2]
    end

    def winner
      return if tie?

      teams_scores.max_by { |ts| ts[1] }[0]
    end

    def tie?
      teams_scores[0][1] == teams_scores[1][1]
    end

    def self.parse_game(game_string)
      team_scores = game_string.split(", ").map { |ts| parse_team_score(ts) }
      new(*team_scores)
    end

    def self.parse_team_score(team_score_string)
      team_score_string.split(/\s(?=\d+$)/).tap do |array|
        array[1] = array[1].to_i
      end
    end
  end

  # Your code goes here...
end
