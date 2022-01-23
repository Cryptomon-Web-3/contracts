// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./MonBattle.sol";

contract MonLiveBattle is MonBattle {
  struct BattlingMons {
    uint256 challengerMon;
    uint256 opponentMon;
  }

  mapping (bytes32 => uint8) public challenges;
  mapping (bytes32 => BattlingMons) public monsInBattle;

  event ChallengeReady(address _player);
  event NewChallenge(address _challenger, address _opponent, uint256 _monId);
  event AcceptChallenge(bytes32 _challengeHash, uint256 _challengerMon, uint256 _opponentMon);
  event AnnounceWinner(bytes32 _challengeHash, uint256 _winnerMon);

  modifier onlyVerifiedPlayer(address _player) {
    require(players[_player].verified, "Player not verified!");
    _;
  }

  modifier onlyChallengeReady(address _player) {
    require(players[_player].challengeReady, "Player is not ready for a challenge");
    _;
  }

  function getChallengeReadyPlayers() public view returns (address[] memory) {
    uint readyCount = 0;
    for(uint i = 0; i < playerAddresses.length; i++) {
      if(players[playerAddresses[i]].challengeReady) readyCount++;
    }

    address[] memory challengeReadyPlayers = new address[](readyCount);

    uint counter = 0;
    for(uint i = 0; i < playerAddresses.length; i++) {
      if(players[playerAddresses[i]].challengeReady)
        challengeReadyPlayers[counter++] = playerAddresses[i];
    }

    return challengeReadyPlayers;
  } 

  function setChallengeReady() public onlyVerifiedPlayer(msg.sender) {
    require(!players[msg.sender].challengeReady, "Already challenge ready!");
    players[msg.sender].challengeReady = true;

    emit ChallengeReady(msg.sender);
  }

  function challenge
    (
      address _opponent, 
      uint256 _monId
    ) 
    public
    onlyChallengeReady(msg.sender) 
    onlyChallengeReady(_opponent) 
    onlyMonOwner(_monId)
    {
    bytes32 challengeHash = keccak256(abi.encodePacked(msg.sender, _opponent));
    challenges[challengeHash] = 1;

    monsInBattle[challengeHash] = BattlingMons(_monId, 0);

    players[msg.sender].challengeReady = false;

    emit NewChallenge(msg.sender, _opponent, _monId);
  }

  function accept(address _challenger, uint256 _monId) public {
    bytes32 challengeHash = keccak256(abi.encodePacked(_challenger, msg.sender));
    require(challenges[challengeHash] == 1, "Challenge does not exist");

    challenges[challengeHash] = 2;
    monsInBattle[challengeHash].opponentMon = _monId;

    players[msg.sender].challengeReady = false;

    emit AcceptChallenge(challengeHash, monsInBattle[challengeHash].challengerMon, _monId);
  }

  function settleChallenge(bytes32 _challengeHash, uint8 _randomNumber) public onlyOwner {
    require(challenges[_challengeHash] == 2, "Invalid challenge!");

    BattlingMons memory mons = monsInBattle[_challengeHash];

    uint256 diff;
    uint256 challengerMonScore = cryptoMons[mons.challengerMon].xp;
    uint256 opponentMonScore = cryptoMons[mons.opponentMon].xp;

    if(challengerMonScore >= opponentMonScore) {
      diff = challengerMonScore - opponentMonScore;
      diff = (diff * 100) / 1000; //Normalize 0-1000 diff to 0-100
      challengerMonScore = diff + _randomNumber;
      opponentMonScore = 100 - _randomNumber;

      if(challengerMonScore >= opponentMonScore) {
        uint256 xpChange = calculateXpChange(diff);
        cryptoMons[mons.challengerMon].xp += (10 - xpChange);
        players[monToOwner[mons.challengerMon]].points += (10 - xpChange);
        players[monToOwner[mons.challengerMon]].winCount++;
        players[monToOwner[mons.opponentMon]].lossCount++;
        emit AnnounceWinner(_challengeHash, mons.challengerMon);
      } else {
        uint256 xpChange = calculateXpChange(diff);
        cryptoMons[mons.opponentMon].xp += xpChange;
        players[monToOwner[mons.opponentMon]].points += xpChange;
        players[monToOwner[mons.opponentMon]].winCount++;
        players[monToOwner[mons.challengerMon]].lossCount++;
        emit AnnounceWinner(_challengeHash, mons.opponentMon);
      }
    } else {
      diff = opponentMonScore - challengerMonScore;
      diff = (diff * 100) / 1000; //Normalize 0-1000 diff to 0-100
      opponentMonScore = diff + _randomNumber;
      challengerMonScore = 100 - _randomNumber;

      if(challengerMonScore >= opponentMonScore) {
        uint256 xpChange = calculateXpChange(diff);
        cryptoMons[mons.challengerMon].xp += xpChange;
        players[monToOwner[mons.challengerMon]].points += xpChange;
        players[monToOwner[mons.challengerMon]].winCount++;
        players[monToOwner[mons.opponentMon]].lossCount++;
        emit AnnounceWinner(_challengeHash, mons.challengerMon);
      } else {
        uint256 xpChange = calculateXpChange(diff);
        cryptoMons[mons.opponentMon].xp += (10 - xpChange);
        players[monToOwner[mons.opponentMon]].points += (10 - xpChange);
        players[monToOwner[mons.opponentMon]].winCount++;
        players[monToOwner[mons.challengerMon]].lossCount++;
        emit AnnounceWinner(_challengeHash, mons.opponentMon);
      }
    }

    players[monToOwner[mons.challengerMon]].challengeReady = true;
    players[monToOwner[mons.opponentMon]].challengeReady = true;
    
    delete challenges[_challengeHash];
    delete monsInBattle[_challengeHash];
  }

  function calculateXpChange(uint256 _diff) public pure returns (uint256) {
    return ((_diff * 5)/100) + 5;
  }
}
