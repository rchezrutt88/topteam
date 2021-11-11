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
    end

    describe "#loss!" do
      it "does not increment the score with a loss" do
        team.win!
        expect(team.score).to eq(3)
        expect { team.loss! }.not_to change { team.score }
      end
    end

    describe "#tie!" do
      it "increments the score by 1" do
        expect { team.tie! }.to change { team.score }.from(0).to(1)
      end
    end

    describe "sort_by(&:score)" do
      let(:team1) { Topteam::Team.new("team1", wins: 2, ties: 0) }
      let(:team2) { Topteam::Team.new("team2", wins: 1, losses: 1) }
      let(:team3) { Topteam::Team.new("team3", ties: 1) }
      let(:team4) { Topteam::Team.new("team4") }
      let(:teams) { [team1, team2, team3, team4] }

      it "sorts by score" do
        expect(teams.shuffle.max_by(&:score)).to eq(team1)
        expect(teams.shuffle.min_by(&:score)).to eq(team4)
        expect(teams.shuffle.sort_by(&:score)).to eq([team4, team3, team2, team1])
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
        expect(Topteam::Game.parse_game(game_string).teams_scores).to eq([["San Jose Earthquakes", 3],
                                                                          ["Santa Cruz Slugs", 3]])
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
  end

  describe Topteam::Season do
    subject { Topteam::Season.new }
    let(:input) do
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

    describe "#add_game" do
      it "parses a game string into a game object" do
        subject.add_game(input[0])
        expect(subject.games).to be_an_instance_of(Topteam::Game)
      end
    end
  end
end
