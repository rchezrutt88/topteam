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

    def matches_played
      @wins + @losses + @ties
    end

    def score
      (3 * @wins) + @ties
    end
  end

  class Season
    attr_reader :rankings

    def initialize(games)
      @games = games
      @teams = {}
      @rankings = []
    end

    def teams_array
      @teams.values
    end

    def teams; end

    def team_names
      @teams.values.map(&:name)
    end

    def match_days; end

    # TODO: consider overriding <<

    def process_games
      @games.each_with_index do |game, index|
        team1 = if @teams[game.team1.name]
                  @teams[game.team1.name]
                else
                  @teams[game.team1.name] = Team.new(game.team1.name)
                end
        # team1 = @teams[game.team1.name] || @teams[game.team1.name] = Team.new(game.team1.name)
        # team2 = @teams[game.team2.name] || @teams[game.team2.name] = Team.new(game.team2.name)
        team2 = if @teams[game.team2.name]
                  @teams[game.team2.name]
                else
                  @teams[game.team2.name] = Team.new(game.team2.name)
                end

        if game.team1.score > game.team2.score
          team1.win!
          team2.loss!
        else
          team1.tie!
          team2.tie!
        end
        if @teams.values.map(&:matches_played).uniq.length == 1 && ((team_names & @games[index + 1].team_names).length > 0)
          @rankings << @teams.values.sort_by(&:score).map { |team| [team.name, team.score] }
        end
      end
    end

    #  if next game results in one teams matches played being one greater than the others
  end

  class Game

    TeamScore = Struct.new(:name, :score)
    attr_accessor :match_day
    attr_reader :team1, :team2

    def self.parse_game(game_string)
      team_scores = game_string.split(", ").map { |ts| parse_team_score(ts) }
      new(*team_scores)
    end

    def initialize(team1, team2)
      raise TypeError unless [team1, team2].all? { |t| t[0].is_a?(String) && t[1].is_a?(Integer) }

      @team1 = TeamScore.new(team1[0], team1[1])
      @team2 = TeamScore.new(team2[0], team2[1])
    end

    def team_names
      [@team1.name, @team2.name]
    end

    def winner
      return if tie?

      [@team1, @team2].max_by { |t| t.score }.name
    end

    def tie?
      @team1.score == @team2.score
    end

    def self.parse_team_score(team_score_string)
      team_score_string.split(/\s(?=\d+$)/).tap do |array|
        array[1] = array[1].to_i
      end
    end
  end

  # Your code goes here...
end
