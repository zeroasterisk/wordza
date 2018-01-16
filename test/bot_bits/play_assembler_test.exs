defmodule PlayAssemblerTest do
  use ExUnit.Case
  # doctest Wordza.PlayAssembler
  alias Wordza.PlayAssembler
  alias Wordza.GameBoard

  describe "mock board played on" do
    setup do
      Wordza.Dictionary.start_link(:mock)
      game = Wordza.GameInstance.create(:mock, :player_1, :player_2)
      played = [
        %{letter: "A", y: 2, x: 0, value: 1},
        %{letter: "L", y: 2, x: 1, value: 1},
        %{letter: "L", y: 2, x: 2, value: 1},
      ] # <-- played already "ALL" horiz
      game = game |> Map.merge(%{
        board: game
        |> Map.get(:board)
        |> GameBoard.add_letters(played),
        player_1: game
        |> Map.get(:player_1)
        |> Map.merge(%{tiles_in_tray: Wordza.GameTiles.create(:mock_tray)}),
      })
      {:ok, game: game}
    end

    test "create_y should create nil for unplayable word 'A' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles must touch an existing tile"]
    end
    test "create_y should create nil for unplayable word 'ALL' (wrong length)", state do
      start_yx = [0, 2]
      word_start = ["A", "L", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles may not overlap"]
    end
    test "create_y should create nil for unplayable word 'BS' (not in tray)", state do
      start_yx = [0, 2]
      word_start = ["B", "S"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles not in your tray"]
    end
    test "create_y should create nil for unplayable word 'ALL' (no played letter, in y direction)", state do
      start_yx = [0, 3]
      word_start = ["A", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      assert play.valid == false
      assert play.errors == ["Tiles must touch an existing tile"]
    end
    test "create_y should create a play for playable word 'AL'", state do
      start_yx = [0, 2]
      word_start = ["A", "L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      # IO.inspect play
      assert play.direction == :y
      assert play.valid == true
      assert play.errors == []
      assert play.letters_yx == [["A", 0, 2], ["L", 1, 2]]
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "A", value: 1, x: 2, y: 0},
        %Wordza.GameTile{letter: "L", value: 1, x: 2, y: 1},
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      assert play.words == [
        [
          %{bonus: :tl, letter: "A", value: 1, x: 2, y: 0},
          %{bonus: nil, letter: "L", value: 1, x: 2, y: 1},
          %{bonus: :st, letter: "L", value: 1, x: 2, y: 2},
        ]
      ]
      assert play.score == 5 # ((1*3) + 1 + 1) [no :st double word, already played]
    end
    test "create_y should create a play for a word 'L' after the already played 'A'", state do
      start_yx = [3, 0]
      word_start = ["L"]
      play = %Wordza.GamePlay{} = PlayAssembler.create_y(state[:game], :player_1, start_yx, word_start)
      # IO.inspect play
      assert play.direction == :y
      assert play.valid == true
      assert play.errors == []
      assert play.tiles_in_play == [
        %Wordza.GameTile{letter: "L", value: 1, x: 0, y: 3},
      ]
      assert play.tiles_in_tray == [
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "A", value: 1},
        %Wordza.GameTile{letter: "L", value: 1},
        %Wordza.GameTile{letter: "N", value: 1},
      ]
      assert play.words == [
        [
          %{bonus: :dl, letter: "A", value: 1, x: 0, y: 2},
          %{bonus: nil, letter: "L", value: 1, x: 0, y: 3},
        ]
      ]
      assert play.score == 2 # (1 + 1) [no :dl double letter, already played]
    end
  end
end

