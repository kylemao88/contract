const { expect } = require("chai");

describe("Ballot contract", function () {
  let Ballot;
  let ballot;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    Ballot = await ethers.getContractFactory("Ballot");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    const proposalNames = ['0x6161616161616161616161616161616161616161616161616161616161616161', '0x6262626262626262626262626262626262626262626262626262626262626262'];
    ballot = await Ballot.deploy(proposalNames);
    // await ballot.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await ballot.chairperson()).to.equal(owner.address);
    });

    it("Should give right to vote", async function () {
      await ballot.giveRightToVote(addr1.address);
      const voter = await ballot.voters(addr1.address);
      expect(voter.weight).to.equal(1);
    });

    it("Should not allow self-delegation", async function () {
      await ballot.giveRightToVote(addr1.address);
      await expect(ballot.connect(addr1).delegate(addr1.address)).to.be.revertedWith("Self-delegatetion isnot allowed.");
    });

    it("Should allow voting", async function () {
      await ballot.giveRightToVote(addr1.address);
      await ballot.connect(addr1).vote(0);
      const proposal = await ballot.proposals(0);
      expect(proposal.voteCount).to.equal(1);
    });

    it("Should return winning proposal and winner name", async function () {
      await ballot.giveRightToVote(addr1.address);
      await ballot.connect(addr1).vote(0);
      const winningProposal = await ballot.winningProposal();
      //const winnerName = ethers.utils.parseBytes32String(await ballot.winnerName());
      //const winnerName = ethers.utils.fixedBytes.parseBytes32String(await ballot.winnerName());
      expect(winningProposal).to.equal(0);
      //expect(winnerName).to.equal('Proposal 1');
    });
  });
});

