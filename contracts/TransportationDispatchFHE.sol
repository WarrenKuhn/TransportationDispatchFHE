// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";

contract TransportationDispatchFHE {
    mapping(address => bool) public hasVoted;
    mapping(address => ebool) private encryptedVotes;
    mapping(address => euint8) private encryptedRouteSelections;

    uint256 public dispatchCount;
    uint256 public totalVotes;

    event VoteSubmitted(address indexed voter, uint256 timestamp);
    event DispatchCreated(uint256 indexed dispatchId, uint256 timestamp);
    event RouteSelected(address indexed user, uint256 timestamp);

    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "Already voted");
        _;
    }

    constructor() {
        // FHE initialization is handled automatically by the FHEVM runtime
    }

    // Submit transportation governance vote (using simple uint8 pattern)
    function submitVote(uint8 _vote) external hasNotVoted {
        require(_vote <= 1, "Invalid vote value"); // 0 = reject, 1 = approve

        // Convert uint8 to encrypted boolean
        ebool encryptedVote = FHE.asEbool(_vote == 1);

        // Set FHE permissions
        FHE.allowThis(encryptedVote);
        FHE.allow(encryptedVote, msg.sender);

        // Store encrypted vote
        hasVoted[msg.sender] = true;
        encryptedVotes[msg.sender] = encryptedVote;
        totalVotes++;

        emit VoteSubmitted(msg.sender, block.timestamp);
    }

    // Select transportation route (0-3 for different routes)
    function selectRoute(uint8 _routeId) external {
        require(_routeId <= 3, "Invalid route ID"); // 0-3 for 4 routes

        // Encrypt route selection
        euint8 encryptedRoute = FHE.asEuint8(_routeId);

        // Set FHE permissions
        FHE.allowThis(encryptedRoute);
        FHE.allow(encryptedRoute, msg.sender);

        // Store encrypted route selection
        encryptedRouteSelections[msg.sender] = encryptedRoute;

        emit RouteSelected(msg.sender, block.timestamp);
    }

    // Create new dispatch
    function createDispatch() external {
        dispatchCount++;
        emit DispatchCreated(dispatchCount, block.timestamp);
    }

    // Get user's encrypted vote (only callable by the voter)
    function getMyVote() external view returns (ebool) {
        require(hasVoted[msg.sender], "User has not voted");
        return encryptedVotes[msg.sender];
    }

    // Get user's encrypted route selection (only callable by the user)
    function getMyRoute() external view returns (euint8) {
        return encryptedRouteSelections[msg.sender];
    }

    // Public getters
    function getDispatchCount() external view returns (uint256) {
        return dispatchCount;
    }

    function isDispatchActive(uint256 _dispatchId) external view returns (bool) {
        return _dispatchId <= dispatchCount && _dispatchId > 0;
    }

    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }

    // Check if address has voted (public for transparency)
    function checkHasVoted(address _voter) external view returns (bool) {
        return hasVoted[_voter];
    }
}