const SuperChef = artifacts.require("SuperChef");
const StakingToken = artifacts.require("StakingToken");
const StakingChef = artifacts.require("StakingChef");

module.exports = async function(deployer) {
  const num = 1 * Math.pow(10, 18);
  const numAsHex = "0x" + num.toString(16);
  await deployer.deploy(StakingToken, 'StableX Staking Token', 'STAX2W', numAsHex)
  await deployer.deploy(StakingToken, 'StableX Staking Token', 'STAX1M', numAsHex)
  await deployer.deploy(StakingToken, 'StableX Staking Token', 'STAX1Y', numAsHex)

  await deployer.deploy(StakingChef, '0xC80991F9106e26e43Bf1C07C764829a85f294C71', '0x0Da6Ed8B13214Ff28e9Ca979Dd37439e8a88F6c4', '0x349693cA57cFfc6F5fD47eAF879812Ad200b1144','1903600', '2306800','5')
  const chef1 = await StakingChef.deployed();
  const stakingToken1 = await StakingToken.at('0x349693cA57cFfc6F5fD47eAF879812Ad200b1144')
  await stakingToken1.mint(chef1.address, '1')
  await chef1.depositToChef('1')

}



