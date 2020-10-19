pragma solidity 0.6.12;

import '@stablex/stablex-swap-lib/contracts/math/SafeMath.sol';
import '@stablex/stablex-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@stablex/stablex-swap-lib/contracts/token/BEP20/SafeBEP20.sol';

import './SuperChef.sol';
import './StaxToken.sol';

contract StakingChef {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public poolId;
    IBEP20 public stakingToken;
    SuperChef public chef;
    StaxToken public stax;

    uint256 public poolAmount;
    uint256 public totalReward;

    mapping (address => uint256) public poolsInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        SuperChef _chef,
        IBEP20 _stax,
        IBEP20 _stakingToken,
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
        if(totalReward == 0) {
            uint256 pending = chef.pendingStax(poolId, address(this));
            return poolsInfo[address(this)].div(poolAmount).mul(pending);
        }
        return poolsInfo[msg.sender].div(poolAmount).mul(totalReward);
    }


    // Deposit stax tokens for Locked Reward allocation.
    function deposit(uint256 _amount) public {
        require (block.number < startBlock, 'not deposit time');
        stax.safeTransferFrom(address(msg.sender), address(this), _amount);
        stakingToken.mint(address(this), _amount);
        chef.deposit(poolId, _amount);
        poolsInfo[msg.sender] = poolsInfo[msg.sender] + _amount;
        poolsAmount = poolsAmount + _amount;
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
        poolsAmount = poolsAmount - poolsInfo[msg.sender];
        emit Withdraw(msg.sender, _amount);
    }

    // EMERGENCY ONLY.
    function emergencyWithdraw(_amount) public onlyOwner {
        stax.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }
}
