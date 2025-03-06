// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "hardhat/console.sol";
import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS is CommitReveal {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0-4 for choices
    mapping(address => bool) public player_committed;
    mapping(address => bool) public player_not_revealed;
    mapping(uint => string) public choices;
    address[] public players;
    address[] public allowed_players;

    TimeUnit public timeUnit = new TimeUnit();

    constructor() {
        allowed_players.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        allowed_players.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        allowed_players.push(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        allowed_players.push(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        choices[0] = "Rock";
        choices[1] = "Paper";
        choices[2] = "Scissors";
        choices[3] = "Spock";
        choices[4] = "Lizard";
    }

    uint public numReveal = 0;
    uint public numCommit = 0;

    function addPlayer() public payable {
        bool exist_player = false;
        require(numPlayer < 2, "Maximum 2 players");
        for (uint i = 0; i < allowed_players.length; i++) {
            if (allowed_players[i] == msg.sender) {
                exist_player = true;
                break;
            }
        }
        require(exist_player, "Player not subscribed");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Player already added");
        }
        require(msg.value == 1 ether, "Must pay 1 ether");
        timeUnit.setStartTime(); // Phase 1 start (waiting for another player to join)
        reward += msg.value;
        players.push(msg.sender);
        numPlayer++;
        player_not_revealed[msg.sender] = true;
    }

    function refundMatching() public {
        require(
            numPlayer == 1,
            "refundMatching can be utilize only when there is one player"
        );
        require(timeUnit.elapsedMinutes() > 1, "wait for awhile to refund"); // if first player waits for too long, he will be able to quit
        address payable player1 = payable(players[0]);
        player1.transfer(reward);

        // restart the game
        reward = 0;
        numPlayer = 0;
        delete player_not_revealed[players[0]];
        players = new address[](0);
    }

    function cancelMatch() public {
        require(
            numPlayer == 2,
            "cancelMatch can be utilize only when there are two player"
        );
        require(
            numCommit == 1,
            "Both players haven't committed yet or both players have already committed"
        );
        require(
            timeUnit.elapsedMinutes() > 1,
            "please wait for another player to choose his/her choice"
        ); // if player(that hasn't selected) not select in 1 min, another player can ask for refund and cancel the match
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        account0.transfer(reward / 2);
        account1.transfer(reward / 2);

        // restart the game
        reward = 0;
        numPlayer = 0;
        numCommit = 0;
        delete player_not_revealed[players[0]];
        delete player_not_revealed[players[1]];
        delete player_committed[players[0]];
        delete player_committed[players[1]];
        players = new address[](0);
    }

    function isPlayer(address _addr) private view returns (bool) {
        return (numPlayer > 0 &&
            (_addr == players[0] || (numPlayer > 1 && _addr == players[1])));
    }

    function commit(bytes32 dataHash) public override {
        require(numPlayer == 2, "Need 2 players to open a commit feature");
        require(isPlayer(msg.sender), "Not a player");
        require(!player_committed[msg.sender], "Already committed");
        console.log(msg.sender);
        timeUnit.setStartTime(); // Counting time start from first commit
        super.commit(dataHash);
        player_committed[msg.sender] = true;
        numCommit++;
    }

    function reveal(bytes32 revealHash) public override {
        require(isPlayer(msg.sender), "Not a player");
        require(player_committed[msg.sender], "Not committed");
        require(player_not_revealed[msg.sender], "Already revealed");
        require(numCommit == 2, "Both players haven't committed yet");
        super.reveal(revealHash);

        uint8 choice = uint8(uint256(revealHash)); // Extract last byte
        require(choice <= 4, "Invalid choice");
        player_choice[msg.sender] = choice;
        player_not_revealed[msg.sender] = false;
        numReveal++;

        if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if ((p0Choice + 1) % 5 == p1Choice || (p1Choice + 2) % 5 == p0Choice) {
            account1.transfer(reward);
            console.log("%s beats %s", choices[p1Choice], choices[p0Choice]);
            console.log("Player 1 wins!!!");
        } else if (
            (p1Choice + 1) % 5 == p0Choice || (p0Choice + 2) % 5 == p1Choice
        ) {
            account0.transfer(reward);
            console.log("%s beats %s", choices[p0Choice], choices[p1Choice]);
            console.log("Player 0 wins!!!");
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        // Reset game state
        numReveal = 0;
        reward = 0;
        numPlayer = 0;
        numCommit = 0;
        for (uint i = 0; i < players.length; i++) {
            delete player_committed[players[i]];
            delete player_not_revealed[players[i]];
            delete player_choice[players[i]];
        }
        players = new address[](0);
    }
}
