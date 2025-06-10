// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SecureAggregation
 * @dev Implements simple reputation, staking, and submission tracking for federated clients
 */
contract SecureAggregation {
    // Address with administrative privileges
    address public owner;

    // Reputation score for each client; influences ban status
    mapping(address => uint256) public reputationScores;

    // Flag indicating whether a client is banned
    mapping(address => bool) public bannedClients;

    // Registry of accepted query hashes (qhashes)
    mapping(bytes32 => bool) public validQhashes;

    // Tracks the highest accuracy reported by each client
    mapping(address => uint256) public lastAccuracy;

    // Number of penalty strikes against each client
    mapping(address => uint256) public penalties;

    // Amount of tokens staked by each client as collateral
    mapping(address => uint256) public stakedTokens;

    // Events to emit when key state changes occur
    event QhashSubmitted(address indexed client, bytes32 qhash);
    event ReputationUpdated(address indexed client, uint256 newScore);
    event MaliciousClientPenalized(address indexed client, uint256 penaltyCount);
    event AccuracyUpdated(address indexed client, uint256 newAccuracy);
    event StakedTokensUpdated(address indexed client, uint256 newStakedAmount);

    /**
     * @dev Restricts function access to the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev Sets the deployer as the initial owner
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Submit a batch of query hashes for validation
     * @param qhashes Array of query hashes to register
     * @param client Address of the client submitting (could be msg.sender)
     * @dev Requires client not banned; emits QhashSubmitted per hash
     */
    function submitBatch(bytes32[] memory qhashes, address client) public {
        require(!bannedClients[client], "Client is banned from submitting updates");
        
        for (uint256 i = 0; i < qhashes.length; i++) {
            // Mark each qhash as valid
            validQhashes[qhashes[i]] = true;
            emit QhashSubmitted(client, qhashes[i]);
        }
    }

    /**
     * @notice Update a client's reputation based on validity of their update
     * @param client Address of the client whose reputation changes
     * @param validUpdate True if the update was valid, false otherwise
     * @dev Only the owner can call; bans client if reputation <= 0
     */
    function updateReputation(address client, bool validUpdate) public onlyOwner {
        if (validUpdate) {
            // Reward valid contributions
            reputationScores[client] += 1;
        } else {
            // Penalize invalid contributions
            reputationScores[client] -= 2;
            // Ban if reputation falls to zero or below
            if (reputationScores[client] <= 0) {
                bannedClients[client] = true;
            }
        }
        emit ReputationUpdated(client, reputationScores[client]);
    }

    /**
     * @notice Check if a client is allowed to participate
     * @param client Address to query
     * @return True if not banned, false otherwise
     */
    function checkReputation(address client) public view returns (bool) {
        return !bannedClients[client];
    }

    /**
     * @notice Validate a single qhash and update accuracy
     * @param qhash Query hash to register
     * @param sender Address of the client submitting the hash
     * @param newAccuracy Reported accuracy; must not decrease
     * @dev Ensures monotonic accuracy growth
     */
    function validateAndStoreQhash(bytes32 qhash, address sender, uint256 newAccuracy) public {
        require(newAccuracy >= lastAccuracy[sender], "Accuracy must not decrease");
        validQhashes[qhash] = true;
        lastAccuracy[sender] = newAccuracy;
        emit AccuracyUpdated(sender, newAccuracy);
    }

    /**
     * @notice Penalize a malicious client by subtracting staked tokens
     * @param client Address of the client to penalize
     * @dev Only owner can call; bans after >3 penalties
     */
    function penalizeMaliciousClient(address client) public onlyOwner {
        penalties[client] += 1;
        // Subtract stake; consider require to prevent underflow
        stakedTokens[client] -= 10;
        if (penalties[client] > 3) {
            bannedClients[client] = true;
        }
        emit MaliciousClientPenalized(client, penalties[client]);
    }

    /**
     * @notice Increase the amount of tokens a client has staked
     * @param client Address of the client
     * @param amount Number of tokens to add
     * @dev Could be improved by making this function payable and using ERC20 transfers
     */
    function stakeTokens(address client, uint256 amount) public onlyOwner {
        stakedTokens[client] += amount;
        emit StakedTokensUpdated(client, stakedTokens[client]);
    }
}
