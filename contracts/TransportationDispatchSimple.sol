// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";

contract TransportationDispatchSimple {
    mapping(address => bool) public hasVoted;
    mapping(address => ebool) private votes;

    uint256 public totalVotes;
    uint256 public dispatchCount;

    event VoteSubmitted(address indexed voter, uint256 timestamp);
    event DispatchCreated(uint256 indexed dispatchId, uint256 timestamp);

    // Submit vote using the proven submitGuess pattern
    function submitVote(uint8 _vote) external {
        require(!hasVoted[msg.sender], "Already voted");
        require(_vote <= 1, "Invalid vote: must be 0 or 1");

        // Convert uint8 to encrypted boolean (FHE encryption)
        ebool encryptedVote = FHE.asEbool(_vote == 1);

        // Store encrypted vote
        votes[msg.sender] = encryptedVote;
        hasVoted[msg.sender] = true;
        totalVotes++;

        emit VoteSubmitted(msg.sender, block.timestamp);
    }

    // Submit route selection
    function submitRoute(uint8 _routeId) external {
        require(_routeId <= 3, "Invalid route: must be 0-3");

        // For simplicity, just emit event - can be extended with storage
        emit DispatchCreated(_routeId, block.timestamp);
    }

    // Public view functions
    function checkHasVoted(address _voter) external view returns (bool) {
        return hasVoted[_voter];
    }

    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }

    function getDispatchCount() external view returns (uint256) {
        return dispatchCount;
    }

    function isDispatchActive(uint256 _dispatchId) external pure returns (bool) {
        return _dispatchId > 0 && _dispatchId <= 10; // Simple active check
    }

    // Create dispatch manually
    function createDispatch() external {
        dispatchCount++;
        emit DispatchCreated(dispatchCount, block.timestamp);
    }
}