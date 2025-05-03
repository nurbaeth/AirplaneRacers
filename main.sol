// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract AirplaneRacers {
    address public owner;
    uint256 public raceId;
    uint8 public maxPlayers = 5;
    uint8 public totalStages = 5;

    enum RaceState { Waiting, Started, Finished }

    struct Player {
        address addr;
        uint8 stage;
        bool finished;
    }

    struct Race {
        RaceState state;
        Player[] players;
        address winner;
    }

    mapping(uint256 => Race) public races;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier inState(uint256 _raceId, RaceState _state) {
        require(races[_raceId].state == _state, "Wrong state");
        _;
    }

    constructor() {
        owner = msg.sender;
        raceId = 1;
        races[raceId].state = RaceState.Waiting;
    }

    function joinRace() external inState(raceId, RaceState.Waiting) {
        Race storage race = races[raceId];
        require(race.players.length < maxPlayers, "Race full");

        // Check for duplicates
        for (uint8 i = 0; i < race.players.length; i++) {
            require(race.players[i].addr != msg.sender, "Already joined");
        }

        race.players.push(Player(msg.sender, 0, false));

        if (race.players.length == maxPlayers) {
            race.state = RaceState.Started;
        }
    }

    function playRound() external inState(raceId, RaceState.Started) {
        Race storage race = races[raceId];

        for (uint8 i = 0; i < race.players.length; i++) {
            if (!race.players[i].finished) {
                // Random progress: 0 or 1 stage forward
                if (random() % 2 == 1) {
                    race.players[i].stage += 1;
                }

                if (race.players[i].stage >= totalStages) {
                    race.players[i].finished = true;
                    race.winner = race.players[i].addr;
                    race.state = RaceState.Finished;
                    break;
                }
            }
        }
    }

    function getCurrentRacePlayers() external view returns (Player[] memory) {
        return races[raceId].players;
    }

    function startNewRace() external onlyOwner {
        require(races[raceId].state == RaceState.Finished, "Previous race not finished");
        raceId++;
        races[raceId].state = RaceState.Waiting;
    }

    function random() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender
                )
            )
        );
    }
}
