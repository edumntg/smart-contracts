// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.3;

contract Voting {
    struct Candidate {
        string name;
        uint256 votes;
    }

    struct Voter {
        bool voted;
        uint256 vote;
    }

    uint256 private candidatesCount = 0;

    address private chairPerson;

    uint private deployDate;
    uint private votingDays = 30; // 30 days by default
    uint private validUntil;

    Candidate[] candidates;
    mapping(address => Voter) voters;

    constructor(string[] memory candidatesNames, uint _votingDays) {
        require(_votingDays > 0, "Voting days must be positive");
        for (uint i = 0; i < candidatesNames.length; i++) {
            candidates.push(Candidate({
                name: candidatesNames[i],
                votes: 0
            }));
            candidatesCount++;
        }

        chairPerson = msg.sender;
        voters[chairPerson].voted = false;

        // declare the voting time
        votingDays = _votingDays;
        deployDate = block.timestamp;
        validUntil = deployDate + votingDays * 24 * 60 * 60;

    }

    // helper method
    function max(uint a, uint b) internal pure returns (uint) {
        uint maxval = a;
        if(b > maxval) {
            maxval = b;
        }

        return maxval;
    }

    function vote(uint256 candidateIndex) public {
        require(candidateIndex <= max(0, candidatesCount-1), "Invalid index");
        require(!voters[msg.sender].voted, "You already voted");
        require(block.timestamp <= validUntil, "Voting has closed");
        Voter storage sender = voters[msg.sender];
        sender.voted = true;
        sender.vote = candidateIndex;
        candidates[candidateIndex].votes++;
    }

    function getCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory candidatesArr = new Candidate[](candidatesCount);
        for (uint i = 0; i < candidatesCount; i++) {
            candidatesArr[i] = candidates[i];
        }

        return candidatesArr;
    }
}