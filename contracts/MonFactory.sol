// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract MonFactory is Ownable {
  uint256 BASE_XP = 10;
  uint256 SHINY_BASE_XP = 50;
  uint256 BATTLE_COOLDOWN_TIME = 1 days;
  uint256 BREED_COOLDOWN_TIME = 30 days;
  uint256 MAX_SHINY = 100;

  struct CryptoMon {
    uint256 id;
    string name;
    string gender;
    uint256 xp;
    uint256 battleReadyTime;
    uint256 breedReadyTime;
    uint16 pokemonId;
    uint16 evolutionLevel;
    bool battleReady;
    bool shiny;
  }

  struct Player {
    string name;
    string avatar;
    bool verified;
    bool receivedFirstCryptoMon;
    bool challengeReady;
    uint256 monCount;
    uint256 winCount;
    uint256 lossCount;
    uint256 points;
  }

  /**
  * Contains the list of all present cryptoMons
  * The unique ID is the index of the cryptoMon
  */
  CryptoMon[] public cryptoMons;
  address[] public playerAddresses;

  //Mapping to store the addresses and corresponding player details
  mapping (address => Player) public players;

  /**
  * Mapping to store the owner of all cryptomons. 
  * Key is the unique ID of the cryptomon and 
  * value is the address of the owner of that cryptomon
  */
  mapping (uint256 => address) public monToOwner;
  mapping(uint16 => uint256) public shinyCount;

  event NewPlayer(address _player);
  event NewCryptoMon(address _player, uint16[] _pokemonIds, bool[] _shiny);

  /**
   * Creates a new User
   */
  function createUser
    (
      string memory _name, 
      string memory _avatar
    ) public {
    require(!players[msg.sender].verified, "You already have an account!");
    players[msg.sender] = Player(_name, _avatar, true, false, false, 0, 0, 0, 0);
    playerAddresses.push(msg.sender);

    emit NewPlayer(msg.sender);
  }

  /**
   * Creates first cryptoMons for Users who haven't received their first cryptoMons yet
   */
  function createFirstCryptoMon
    (
      string[] memory _names, 
      string[] memory _genders, 
      uint16[] memory _pokemonIds,
      uint8 _randomNumber,
      address _player
    ) public onlyOwner {
    require(!players[_player].receivedFirstCryptoMon, "You already received your first cryptoMon!");

    bool[] memory shiny = new bool[](_pokemonIds.length);

    if(_randomNumber == 5) {
      for(uint i = 0; i < _pokemonIds.length; i++) {
        if(shinyCount[_pokemonIds[i]] < MAX_SHINY) {
          shiny[i] = true;
          shinyCount[_pokemonIds[i]]++;
          break;
        }
      }
    }

    _createNewCryptoMon(_names, _genders, _pokemonIds, shiny, _player);
    players[_player].receivedFirstCryptoMon = true;
  }

  /**
   * Generates new cryptoMons for a player
   */
  function _createNewCryptoMon
    (
      string[] memory _names, 
      string[] memory _genders, 
      uint16[] memory _pokemonIds,
      bool[] memory _shiny,
      address _player
    ) internal {
    require(players[_player].verified, "You're not verified!");
    for(uint i = 0; i < _names.length; i++) {
      cryptoMons.push(CryptoMon(
        cryptoMons.length,
        _names[i],
        _genders[i],
        _shiny[i] ? SHINY_BASE_XP : BASE_XP,
        block.timestamp,
        block.timestamp,
        _pokemonIds[i],
        1,
        false,
        _shiny[i]
      ));
      uint id = cryptoMons.length - 1;

      monToOwner[id] = _player;
    }

    players[_player].monCount += _names.length;

    emit NewCryptoMon(_player, _pokemonIds, _shiny);
  }

  function getCryptoMonsByOwner(address _owner) public view returns (CryptoMon[] memory) {
    CryptoMon[] memory ownedCryptoMons = new CryptoMon[](players[_owner].monCount);
    uint index = 0;
    for(uint i = 0; i < cryptoMons.length; i++) {
      if(monToOwner[i] == _owner) {
        ownedCryptoMons[index] = cryptoMons[i];
        index++;
      }
    }

    return ownedCryptoMons;
  }
  
  function deletePlayerBackdoor(address _player) public {
      players[_player].verified = false;
  }
  
  function setChallengeReadyBackdoor(address _player, bool _value) public {
      players[_player].challengeReady = _value;
  } 
}
