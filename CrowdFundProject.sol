// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdfundingPlatform {
    // Campaign struct
    struct Campaign {
        uint256 id;
        string name;
        string description;
        uint256 targetAmount;
        uint256 deadline;
        address creator;
        uint256 totalContributed;
        bool finalized;
        CampaignStatus status;
    }

    // Milestone struct
    struct Milestone {
        uint256 amount;
        string description;
        uint256 approvalCount;
        mapping(address => bool) hasVoted;
    }

    // Contribution struct
    struct Contribution {
        uint256 campaignId;
        address contributor;
        uint256 amount;
    }

    // Campaign status enum
    enum CampaignStatus { Active, Successful, Failed }

    // Mappings
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Contribution[]) public contributions;
    uint256 public nextCampaignId = 1;

    // Events
    event CampaignCreated(uint256 indexed campaignId, string name, uint256 targetAmount, uint256 deadline);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event FundsReleased(uint256 indexed campaignId, uint256 amount);
    event CampaignFinalized(uint256 indexed campaignId, CampaignStatus status);

    // Create a new campaign
    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _targetAmount,
        uint256 _deadline
    ) public {
        campaigns[nextCampaignId] = Campaign(
            nextCampaignId,
            _name,
            _description,
            _targetAmount,
            _deadline,
            msg.sender,
            0,
            false,
            CampaignStatus.Active
        );
        emit CampaignCreated(nextCampaignId, _name, _targetAmount, _deadline);
        nextCampaignId++;
    }

    // Contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign deadline has passed");
        require(campaign.totalContributed + msg.value <= campaign.targetAmount, "Campaign target reached");
        require(campaign.status == CampaignStatus.Active, "Campaign is not active");

        contributions[_campaignId].push(Contribution(_campaignId, msg.sender, msg.value));
        campaign.totalContributed += msg.value;
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    // Finalize a campaign
    function finalizeCampaign(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline || campaign.totalContributed >= campaign.targetAmount, "Campaign is still active");
        require(!campaign.finalized, "Campaign already finalized");

        if (campaign.totalContributed >= campaign.targetAmount) {
            campaign.status = CampaignStatus.Successful;
        } else {
            campaign.status = CampaignStatus.Failed;
        }

        campaign.finalized = true;
        emit CampaignFinalized(_campaignId, campaign.status);
    }

    // View functions
    function getCampaignDetails(uint256 _campaignId) public view returns (
        uint256 id, string memory name, string memory description, uint256 targetAmount, uint256 deadline, address creator, uint256 totalContributed, bool finalized, CampaignStatus status
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.id, campaign.name, campaign.description, campaign.targetAmount, campaign.deadline, campaign.creator, campaign.totalContributed, campaign.finalized, campaign.status
        );
    }

    function getContributorInfo(uint256 _campaignId, address _contributor) public view returns (uint256 amount) {
        Contribution[] storage contributorList = contributions[_campaignId];
        for (uint256 i = 0; i < contributorList.length; i++) {
            if (contributorList[i].contributor == _contributor) {
                return (contributorList[i].amount);
            }
        }
        return (0);
    }

    function getAllCampaigns() public view returns (uint256[] memory) {
        uint256[] memory campaignIds = new uint256[](nextCampaignId - 1);
        for (uint256 i = 1; i < nextCampaignId; i++) {
            campaignIds[i - 1] = i;
        }
        return campaignIds;
    }

    function getCampaignContributors(uint256 _campaignId) public view returns (address[] memory) {
        Contribution[] storage contributorList = contributions[_campaignId];
        address[] memory contributors = new address[](contributorList.length);
        for (uint256 i = 0; i < contributorList.length; i++) {
            contributors[i] = contributorList[i].contributor;
        }
        return contributors;
    }

    function getTotalContributions(uint256 _campaignId) public view returns (uint256) {
        return campaigns[_campaignId].totalContributed;
    }
}