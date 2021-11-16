# frozen_string_literal: true

RSpec.describe Topteam do
  it "has a version number" do
    expect(Topteam::VERSION).not_to be nil
  end
  describe Topteam::Team do
    let(:team) { Topteam::Team.new("team1") }
    describe "#win!" do
      it "increments the score by 3" do
        expect { team.win! }.to change { team.score }.from(0).to(3)
      end
      it "increments matches played" do
        expect { team.win! }.to change { team.matches_played }.from(0).to(1)
      end
    end
    describe "#loss!" do
      it "does not increment the score with a loss" do
        team.win!
        expect(team.score).to eq(3)
        expect { team.loss! }.not_to change { team.score }
      end
      it "increments matches played" do
        expect { team.loss! }.to change { team.matches_played }.from(0).to(1)
      end
    end
    describe "#tie!" do
      it "increments the score by 1" do
        expect { team.tie! }.to change { team.score }.from(0).to(1)
      end
      it "increments matches played" do
        expect { team.tie! }.to change { team.matches_played }.from(0).to(1)
      end
    end
  end

  describe Topteam::Game do
    let(:game_string) { "San Jose Earthquakes 3, Santa Cruz Slugs 3" }
    let(:game) { Topteam::Game.parse_game(game_string) }
    describe ".parse_game" do
      it "returns a game" do
        expect(Topteam::Game.parse_game(game_string)).to be_a(Topteam::Game)
      end
      it "contains the tuples consisting of the team name and their game score" do
        expect(Topteam::Game.parse_game(game_string).team_score_tuples).to contain_exactly(["San Jose Earthquakes", 3],
                                                                                           ["Santa Cruz Slugs", 3])
      end
    end
    describe "#tie?" do
      it "returns true if it's a tie" do
        expect(game.tie?).to eq(true)
      end
    end
    describe "#winner" do
      context do
        let(:game_string) { "San Jose Earthquakes 3, Santa Cruz Slugs 4" }
        it "returns the winning team's name" do
          expect(game.winner).to eq("Santa Cruz Slugs")
        end
      end
      it "returns nil if it's a tie" do
        expect(game.winner).to be(nil)
      end
    end
    describe "with malformed input" do
      it "raises a type error" do
        expect { Topteam::Game.new([1, "Santa Cruz Slugs"], [3, "San Jose Earthquakes"]) }
          .to raise_error(ArgumentError, /must be of form/)
      end
    end
  end

  describe Topteam::Season do
    let(:initialize_season) do
      lambda { |input|
        Topteam::Season.new.tap do |season|
          season.add_games(input)
        end
      }
    end

    let(:raw_teams_array) do
      ["San Jose Earthquakes 3, Santa Cruz Slugs 3",
       "Capitola Seahorses 1, Aptos FC 0",
       "Felton Lumberjacks 2, Monterey United 0",

       "Felton Lumberjacks 1, Aptos FC 2",
       "Santa Cruz Slugs 0, Capitola Seahorses 0",
       "Monterey United 4, San Jose Earthquakes 2",

       "Santa Cruz Slugs 2, Aptos FC 3",
       "San Jose Earthquakes 1, Felton Lumberjacks 4",
       "Monterey United 1, Capitola Seahorses 0",

       "Aptos FC 2, Monterey United 0",
       "Capitola Seahorses 5, San Jose Earthquakes 5",
       "Santa Cruz Slugs 1, Felton Lumberjacks 1"]
    end

    let(:expected_teams) do
      [
        "San Jose Earthquakes",
        "Santa Cruz Slugs",
        "Capitola Seahorses",
        "Aptos FC",
        "Felton Lumberjacks",
        "Monterey United"
      ]
    end

    describe "#teams" do
      it "returns an array of all the teams" do
        expected_array = expected_teams.map { |team_name| have_attributes(name: team_name) }
        expect(initialize_season.call(raw_teams_array).teams).to contain_exactly(*expected_array)
      end
    end

    describe "#teams_hash" do
      it "returns a hash of teams with the team names as keys" do
        expected_hash = expected_teams.each_with_object({}) { |team, hash| hash[team] = have_attributes(name: team) }
        expect(initialize_season.call(raw_teams_array).teams_hash).to match(expected_hash)
      end
    end

    describe "#matches_per_day" do
      it "returns the correct number of matches per day" do
        expect(initialize_season.call(raw_teams_array).matches_per_day).to eq 3
      end
    end

    describe "#add_games" do
      let(:season) { Topteam::Season.new }
      describe "yielding the rankings and match day" do
        before do
          expect(season).to receive(:matches_per_day=).with(3).and_call_original
        end
        let(:day_1_rankings) do
          [
            have_attributes(name: "Capitola Seahorses", score: 3),
            have_attributes(name: "Felton Lumberjacks", score: 3),
            have_attributes(name: "San Jose Earthquakes", score: 1)
          ]
        end
        let(:day_2_rankings) do
          [
            have_attributes(name: "Capitola Seahorses", score: 4),
            have_attributes(name: "Aptos FC", score: 3),
            have_attributes(name: "Felton Lumberjacks", score: 3)
          ]
        end
        let(:day_3_rankings) do
          [
            have_attributes(name: "Aptos FC", score: 6),
            have_attributes(name: "Felton Lumberjacks", score: 6),
            have_attributes(name: "Monterey United", score: 6)
          ]
        end
        let(:day_4_rankings) do
          [
            have_attributes(name: "Aptos FC", score: 9),
            have_attributes(name: "Felton Lumberjacks", score: 7),
            have_attributes(name: "Monterey United", score: 6)
          ]
        end
        it "yields the rankings once" do
          expect { |b| season.add_games(raw_teams_array[0..3], &b) }.to yield_with_args(day_1_rankings, 1)
        end
        it "yields the rankings twice" do
          expect do |b|
            season.add_games(raw_teams_array[0..6], &b)
          end.to yield_successive_args([day_1_rankings, 1], [day_2_rankings, 2])
        end
        it "yields the rankings three times" do
          expect do |b|
            season.add_games(raw_teams_array[0..9], &b)
          end.to yield_successive_args([day_1_rankings, 1], [day_2_rankings, 2], [day_3_rankings, 3])
        end
        it "yields the correct rankings four times" do
          expect do |b|
            season.add_games(raw_teams_array, &b)
          end.to yield_successive_args([day_1_rankings, 1], [day_2_rankings, 2], [day_3_rankings, 3],
                                       [day_4_rankings, 4])
        end
      end
    end
  end
end
