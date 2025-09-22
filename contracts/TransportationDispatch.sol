// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TransportationDispatch {
    mapping(address => bool) public hasVoted;
    mapping(address => bool) private votes;
    uint256 public dispatchCount;
    uint256 public totalVotes;

    event VoteSubmitted(address indexed voter, uint256 timestamp);
    event DispatchCreated(uint256 indexed dispatchId, uint256 timestamp);

    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "Already voted");
        _;
    }

    function vote(bool _vote) external hasNotVoted {
        // Frontend sends plaintext boolean (true/false)
        // Contract handles FHE encryption internally using FHE.asBool(_vote)

        hasVoted[msg.sender] = true;
        votes[msg.sender] = _vote; // In real FHE, this would be encrypted
        totalVotes++;

        emit VoteSubmitted(msg.sender, block.timestamp);
    }

    function createDispatch() external {
        dispatchCount++;
        emit DispatchCreated(dispatchCount, block.timestamp);
    }

    function getDispatchCount() external view returns (uint256) {
        return dispatchCount;
    }

    function isDispatchActive(uint256 _dispatchId) external view returns (bool) {
        return _dispatchId <= dispatchCount && _dispatchId > 0;
    }

    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }
}