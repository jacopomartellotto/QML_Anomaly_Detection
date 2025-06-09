// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecureAggregation {
    address public owner;
    mapping(address => uint256) public reputationScores;
    mapping(address => bool) public bannedClients;
    mapping(bytes32 => bool) public validQhashes;
    mapping(address => uint256) public lastAccuracy;
    mapping(address => uint256) public penalties;
    mapping(address => uint256) public stakedTokens;

    event QhashSubmitted(address indexed client, bytes32 qhash);
    event ReputationUpdated(address indexed client, uint256 newScore);
    event MaliciousClientPenalized(address indexed client, uint256 penaltyCount);
    event AccuracyUpdated(address indexed client, uint256 newAccuracy);
    event StakedTokensUpdated(address indexed client, uint256 newStakedAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function submitBatch(bytes32[] memory qhashes, address client) public {
        require(!bannedClients[client], "Client is banned from submitting updates");
        
        for (uint256 i = 0; i < qhashes.length; i++) {
            validQhashes[qhashes[i]] = true;
            emit QhashSubmitted(client, qhashes[i]);
        }
    }

    function updateReputation(address client, bool validUpdate) public onlyOwner {
        if (validUpdate) {
            reputationScores[client] += 1;
        } else {
            reputationScores[client] -= 2;
            if (reputationScores[client] <= 0) {
                bannedClients[client] = true;
            }
        }
        emit ReputationUpdated(client, reputationScores[client]);
    }

    function checkReputation(address client) public view returns (bool) {
        return !bannedClients[client];
    }

    function validateAndStoreQhash(bytes32 qhash, address sender, uint256 newAccuracy) public {
        require(newAccuracy >= lastAccuracy[sender], "Accuracy must not decrease");
        validQhashes[qhash] = true;
        lastAccuracy[sender] = newAccuracy;
        emit AccuracyUpdated(sender, newAccuracy);
    }

    function penalizeMaliciousClient(address client) public onlyOwner {
        penalties[client] += 1;
        stakedTokens[client] -= 10;
        if (penalties[client] > 3) {
            bannedClients[client] = true;
        }
        emit MaliciousClientPenalized(client, penalties[client]);
    }

    function stakeTokens(address client, uint256 amount) public onlyOwner {
        stakedTokens[client] += amount;
        emit StakedTokensUpdated(client, stakedTokens[client]);
    }
}
