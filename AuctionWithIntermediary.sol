// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.3;

contract AuctionWithIntermediary {

    address public owner; // owner of the auction (seller)
    address public winner; // winner of the auction
    address public intermediary; // intermediary

    string auctionDescription; // brief description of the auction

    uint public minimumBid;
    uint public winningBid; // winning bid
    uint public noOfBids;

    uint intermediaryComission; // comission (in wei) for the intermediary

    uint public auctionDeadline; // timestamp of the deadline

    uint public noOfParticipants; // Record no of participants

    struct Participant {
        uint amountBidded;
        uint dateOfBid;
    }

    mapping(address=>Participant) participants;

    // The following variables are used to approve the intermediary once the auction ends and the owner adds the intermediary
    bool public approvedByOwner; 
    bool public approvedByWinner;

    bool public ownerVoted;
    bool public winnerVoted;

    bool public paidByWinner;
    bool public approvedByIntermediary;
    bool public collectedByOwner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Action allowed only to the owner of the auction");
        _;
    }

    modifier onlyWinner() {
        require(winner == msg.sender, "Action allowed only to the winner of the auction");
        _;
    }

    modifier onlyIntermediary() {
        require(intermediary == msg.sender, "Action allowed only to the intermediary of the auction");
        _;
    }

    constructor(string memory _auctionDesc, uint _minimumBid, uint _auctionDays) {
        auctionDescription = _auctionDesc;
        minimumBid = _minimumBid;
        auctionDeadline = block.timestamp + _auctionDays;
        owner = msg.sender;
        intermediaryComission = 0;
        winningBid = minimumBid;
        noOfParticipants = 0;
        noOfBids = 0;
        approvedByOwner = false;
        approvedByWinner = false;
        ownerVoted = false;
        winnerVoted = false;
        paidByWinner = false;
        approvedByIntermediary = false;
        collectedByOwner = false;
        intermediary = address(0);
    }

    function setIntermediary(address _intermediary, uint _comission) public onlyOwner {
        require(intermediary == address(0), "Intermediary already set");

        intermediary = _intermediary;
        intermediaryComission = _comission;
    }

    function bid(uint _value) public {
        require(owner != msg.sender, "Owners cannot bid in the auction");
        require(block.timestamp < auctionDeadline, "Auction is closed");
        require(_value >= minimumBid, "Bid is too low");

        Participant storage participant = participants[msg.sender];

        if(participant.amountBidded == 0) {
            // first time
            noOfParticipants++;
        }

        participant.amountBidded = _value;
        participant.dateOfBid = block.timestamp;
        
        if(participant.amountBidded >= winningBid) {
            winningBid = participant.amountBidded;
            winner = msg.sender;
        }

        noOfBids++;
    }

    function voteOwner(bool _vote) public onlyOwner {
        require(!ownerVoted, "Owner already voted");
        ownerVoted = true;
        approvedByOwner = _vote;
    }

    function voteWinner(bool _vote) public onlyWinner {
        require(!winnerVoted, "Winner already voted");
        winnerVoted = true;
        approvedByWinner = _vote;
    }

    function payBid() public payable onlyWinner {
        // Winner has to pay the bid
        require(msg.value == winningBid, "You must pay an amount equal to the amount bidded");
        require(!paidByWinner, "Winner already paid the bid");
        require(block.timestamp > auctionDeadline, "The auction has not closed yet");
        // At this point, the amount has been paid
        paidByWinner = true;
    }

    function approvePayment() public onlyIntermediary {
        require(paidByWinner, "The bid has not been paid by the winner yet");
        require(approvedByOwner, "Owner has not approved the intermediary");
        require(approvedByWinner, "Winner has not approved the intermediary");
        require(!approvedByIntermediary, "Payment already approved");
        approvedByIntermediary = true;
    }

    function withdraw() public onlyOwner {
        require(approvedByIntermediary, "The payment has not been approved by the intermediary yet");
        require(!collectedByOwner, "You already collected the payment");
        // Send amount to owner
        payable(owner).transfer(winningBid - intermediaryComission);

        // Send commission to intermediary
        payable(intermediary).transfer(intermediaryComission);

        collectedByOwner = true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }



}