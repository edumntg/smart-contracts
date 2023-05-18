// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.3;

contract CrowdFunding {
    // Create variables and structs

    struct Proposal {
        string description;
        address payable recipient;
        uint raisedAmount;
        uint noOfContributors;
        uint target;
        uint deadline;
        mapping(address=>bool) contributors;
        mapping(address=>uint) contributorAmount;
        bool collected;
    }

    struct ProposalRet {
        string description;
        uint raisedAmount;
        uint noOfContributors;
        uint target;
        uint deadline;
        bool collected;
    }

    address public manager;
    mapping(address=>bool) contributors;
    uint public minContribution; // in wei
    uint public noOfContributors;
    uint public noOfProposals;
    mapping(uint=>Proposal) proposals;
    mapping(address=>bool) recipients;

    constructor() {
        minContribution = 100 wei;
        noOfContributors = 0;
        noOfProposals = 0;
        manager = msg.sender; // Manager is the one who deploys the contract
    }

    function createProposal(string memory _description, address payable _recipient, uint _deadline, uint _target) public {
        // Check that the proposal is being created by the manager
        require(msg.sender == manager, "You cannot create new proposals");
        // Check if the recipient has proposal already registered
        require(!recipients[_recipient], "This recipient has a proposal already registered");
        // Check that target is at least the minimum amount
        require(_target >= minContribution, "Target amount must be equal or higher than 100 wei");

        // Create proposal
        Proposal storage proposal = proposals[noOfProposals];
        noOfProposals++;
        proposal.description = _description;
        proposal.recipient = _recipient;
        proposal.raisedAmount = 0;
        proposal.noOfContributors = 0;
        proposal.target = _target;
        proposal.deadline = block.timestamp + _deadline;
        proposal.collected = false;

        recipients[_recipient] = true;
    }

    function getProposals() public view returns (ProposalRet[] memory retProposals) {
        retProposals = new ProposalRet[](noOfProposals);
        for(uint i = 0; i < noOfProposals; i++) {
            retProposals[i] = ProposalRet({
                description: proposals[i].description,
                raisedAmount: proposals[i].raisedAmount,
                noOfContributors: proposals[i].noOfContributors,
                target: proposals[i].target,
                deadline: proposals[i].deadline,
                collected: proposals[i].collected
            });
        }
    }

    function contribute(uint _proposalIndex) public payable {
        // Check that the index is valid
        require(_proposalIndex < noOfProposals, "Proposal index is invalid");
        // Check that amount is valid
        require(msg.value >= minContribution, "Contribution amount must be equal or higher than 100 wei");
        // Check that proposal is active
        Proposal storage proposal = proposals[_proposalIndex];
        require(block.timestamp < proposal.deadline, "This proposal has ended");

        // Do the contribution
        proposal.raisedAmount += msg.value;

        // If this is the first time for this contributor, then increment the contributors counter
        if(!proposal.contributors[msg.sender]) {
            proposal.contributors[msg.sender] = true;
            proposal.noOfContributors++;
        }

        proposal.contributorAmount[msg.sender] += msg.value;
        noOfContributors++;
    }

    function getRefund(uint _proposalIndex) public {
        // This function is executed only if the proposal has finished and did not meet its target
        // Then client can get their money back

        // Validate proposal index
        require(_proposalIndex < noOfProposals, "Proposal index is invalid");
        
        // Get proposal
        Proposal storage proposal = proposals[_proposalIndex];

        // Check deadline
        require(block.timestamp >= proposal.deadline, "This proposal is still active");

        // Check that proposal did not meet its target
        require(proposal.raisedAmount < proposal.target, "You cannot ask a refund from proposals that met their target");
        
        // Check that user contributed in this proposal
        require(proposal.contributors[msg.sender], "You did not contribute to this proposal");

        // Send money to user
        payable(msg.sender).transfer(proposal.contributorAmount[msg.sender]);

        // Delete client from proposal
        proposal.contributors[msg.sender] = false;
        proposal.raisedAmount -= proposal.contributorAmount[msg.sender];
        proposal.contributorAmount[msg.sender] = 0;
        proposal.noOfContributors--;
    }

    function collectAmount(uint _proposalIndex) public {
        // This function sends the raised amount to the owner of the proposal
        // Validate proposal index
        require(_proposalIndex < noOfProposals, "Proposal index is invalid");
        
        // Get proposal
        Proposal storage proposal = proposals[_proposalIndex];

        // Check that the receiver is the one collecting the money
        require(manager == msg.sender, "Only the manager can process payments");

        // Check deadline
        require(block.timestamp > proposal.deadline, "You must wait until the deadline to collect the amount raised");

        // Check that proposal has not been collected yet
        require(!proposal.collected, "This proposal has been already collected");

        // Send money to recipient
        proposal.recipient.transfer(proposal.raisedAmount);
        proposal.collected = true;
    }

}