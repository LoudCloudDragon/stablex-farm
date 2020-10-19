pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

import './SuperChef.sol';
import './StakingToken.sol';

contract StakingChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public poolId;
    StakingToken public stakingToken;
    SuperChef public chef;
    IBEP20 public stax;

    uint256 public poolAmount;
    uint256 public totalReward;

    mapping (address => uint256) public poolsInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        SuperChef _chef,
        IBEP20 _stax,
        StakingToken _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _poolId
    ) public {
        chef = _chef;
        stax = _stax;
        stakingToken = _stakingToken;
        endBlock = _endBlock;
        startBlock = _startBlock;
        poolId = _poolId;
    }

    // View function to see pending Tokens on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        uint256 amount = poolsInfo[msg.sender];
        if(totalReward == 0 && amount > 0) {
            uint256 pending = chef.pendingStax(poolId, address(this));
            return pending.mul(amount).div(poolAmount);
        }
        if (amount > 0) {
            return totalReward.mul(amount).div(poolAmount);
        }
        return 0;
    }


    // Deposit stax tokens for Locked Reward allocation.
    function deposit(uint256 _amount) public {
        require (block.number < startBlock, 'not deposit time');
        stax.safeTransferFrom(address(msg.sender), address(this), _amount);
        stakingToken.mint(address(this), _amount);
        chef.deposit(poolId, _amount);
        poolsInfo[msg.sender] = poolsInfo[msg.sender] + _amount;
        poolAmount = poolAmount + _amount;
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw staking tokens from SuperChef.
    function withdraw() public {
        require (block.number > endBlock, 'not withdraw time');
        if (totalReward == 0) {
            chef.deposit(poolId, 0);
        }
        totalReward = stax.balanceOf(address(this)) - poolAmount;
        uint256 reward = poolsInfo[msg.sender].div(poolAmount).mul(totalReward);
        stax.safeTransfer(address(msg.sender), reward.add(poolsInfo[msg.sender]));
        poolsInfo[msg.sender] = 0;
        poolAmount = poolAmount - poolsInfo[msg.sender];
        emit Withdraw(msg.sender, reward);
    }

    // EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _amount) public onlyOwner {
        stax.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }
}
