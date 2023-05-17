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

    Candidate[] candidates;
    mapping(address => Voter) voters;

    constructor(string[] memory candidatesNames) {
        for (uint i = 0; i < candidatesNames.length; i++) {
            candidates.push(Candidate({
                name: candidatesNames[i],
                votes: 0
            }));
            candidatesCount++;
        }

        chairPerson = msg.sender;
        voters[chairPerson].voted = false;
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