////
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const ONE_GWEI = 1_000_000_000n;

module.exports = buildModule("BallotModule", (m) => {
  
  const lockedAmount = m.getParameter("lockedAmount", ONE_GWEI);

  /*
  const proposalNames = [
    ethers.utils.formatBytes32String("Proposal 1"),
    ethers.utils.formatBytes32String("Proposal 2"),
  ];
  */
  const proposalNames = ['0x6161616161616161616161616161616161616161616161616161616161616161', '0x6262626262626262626262626262626262626262626262626262626262626262'];

  // 因为构造函数，并未带有payable，所以部署此合约不需要传递gas费
  const lock = m.contract("Ballot", [proposalNames] /*, {value: lockedAmount,}*/);

  return { lock };
});