// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./MonFactory.sol";

contract MonBattle is MonFactory {
  //Mapping to store all existing battles
  //Key is a keccak256 hash of the ids of the 2 participating cryptoMons and
  //Value is whether they're currently battling or not
  mapping (bytes32 => bool) battles;

  //Event to notify the oracle when a battle has started so that it can 
  //send a random number to settle the battle
  event StartBattle(uint256 _mon1, uint256 _mon2);

  event SettleBattle(bytes32 _hash, uint256 _winnerMon);

  modifier onlyMonOwner(uint256 _cryptoMonId) {
    require(_cryptoMonId < cryptoMons.length, "Invalid Mon ID");
    require(msg.sender == monToOwner[_cryptoMonId], "You're not the owner of this cryptoMon!");
    _;
  }

  modifier battleReady(uint256 _cryptoMonId) {
    require(_cryptoMonId < cryptoMons.length, "Invalid Mon ID");
    require(cryptoMons[_cryptoMonId].battleReady, "Mon is not battle ready!");
    _;
  }

  /**
   * Sets a cryptoMon to be battle ready. Other players can now battle this mon
   */
  function setBattleReady(uint256 _cryptoMonId) public onlyMonOwner(_cryptoMonId) {
    require(!cryptoMons[_cryptoMonId].battleReady, "Already battle ready!");
    require(block.timestamp >= cryptoMons[_cryptoMonId].battleReadyTime, "Not ready to be battle ready yet!");
    cryptoMons[_cryptoMonId].battleReady = true;
  }

  /**
   * Starts a battle between 2 valid cryptoMons
   * Sets their new battleReadyTime and emits the startBattleEvent
   */
  function startBattle
    (
      uint256 _ownerMon, 
      uint256 _oppositeMon
    ) 
    public 
    onlyMonOwner(_ownerMon) 
    battleReady(_ownerMon) 
    battleReady(_oppositeMon) {
    require(monToOwner[_ownerMon] != monToOwner[_oppositeMon], "You can't battle your own mon!");
    
    cryptoMons[_ownerMon].battleReady = false;
    cryptoMons[_oppositeMon].battleReady = false;
    cryptoMons[_ownerMon].battleReadyTime = block.timestamp + BATTLE_COOLDOWN_TIME;
    cryptoMons[_oppositeMon].battleReadyTime = block.timestamp + BATTLE_COOLDOWN_TIME;

    battles[keccak256(abi.encodePacked(_ownerMon, _oppositeMon))] = true;

    emit StartBattle(_ownerMon, _oppositeMon);
  }

  function settleBattle(uint256 _ownerMon, uint256 _oppositeMon, uint16 _randomNumber) public onlyOwner {
    require(battles[keccak256(abi.encodePacked(_ownerMon, _oppositeMon))], "No such battle!");

    if(_randomNumber > 50) {
      emit SettleBattle(keccak256(abi.encodePacked(_ownerMon, _oppositeMon)), _ownerMon);
    } else {
      emit SettleBattle(keccak256(abi.encodePacked(_ownerMon, _oppositeMon)), _oppositeMon);
    }
  }
}
