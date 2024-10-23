// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CALF is ERC20, Ownable, Pausable {
    // 定义每个用户的质押余额（以 ETH 计）
    mapping(address => uint256) public ethBalances;

    // 定义每个用户的质押时间
    mapping(address => uint256) public stakingTimestamps;

    // 记录用户是否已经质押过
    mapping(address => bool) public hasStaked;

    // 总质押量（以 ETH 计）
    uint256 public totalEthStaked;

    // 奖励等待时间（以秒计）
    uint256 public constant REWARD_DURATION = 30 days;

    // 奖励的上限，最多领取 500 枚 CALF
    uint256 public constant MAX_REWARD = 500 * (10 ** 18); // 500 枚 CALF

    // 奖励领取的截止时间，2024年12月11日的时间戳
    uint256 public constant rewardClaimStartTime = 1733875200; // 2024年12月11日 00:00:00 UTC

    // 事件定义
    event StakedETH(address indexed user, uint256 amount);
    event UnstakedETH(address indexed user, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    // 构造函数
    constructor(uint256 initialSupply) ERC20("CALF", "CALF") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    // 质押 ETH，不会立即获得 CALF 代币，质押金额不得小于 0.001 ETH 且每个用户只能质押一次
    function stake() external payable {
        require(msg.value >= 0.001 ether, "Minimum stake is 0.001 ETH");
        require(!hasStaked[msg.sender], "You have already staked");

        ethBalances[msg.sender] += msg.value;
        totalEthStaked += msg.value;

        // 记录质押时间和质押状态
        stakingTimestamps[msg.sender] = block.timestamp;
        hasStaked[msg.sender] = true;

        emit StakedETH(msg.sender, msg.value);
    }

    // 解除质押并返还 ETH
    function unstake(uint256 amount) external {
        require(ethBalances[msg.sender] >= amount, "Insufficient staked ETH balance");

        // 使用 call 方法进行 ETH 转账以提高安全性
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        // 更新状态以防止重入攻击
        ethBalances[msg.sender] -= amount;
        totalEthStaked -= amount;

        emit UnstakedETH(msg.sender, amount);
    }

    // 领取奖励
    function claimReward() external {
        require(ethBalances[msg.sender] > 0, "No ETH staked");
        require(block.timestamp >= stakingTimestamps[msg.sender] + REWARD_DURATION, "Staking period not complete");
        require(block.timestamp >= rewardClaimStartTime, "Cannot claim reward before December 11, 2024");

        uint256 stakedBalance = ethBalances[msg.sender]; // 提取以减少存储访问
        uint256 reward = stakedBalance * 50;

        // 限制奖励上限为 500 CALF
        if (reward > MAX_REWARD) {
            reward = MAX_REWARD;
        }

        // 铸造奖励代币
        _mint(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // 合约拥有者铸造更多代币
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // 查询用户的质押 ETH 余额
    function getStakedBalance(address user) external view returns (uint256) {
        return ethBalances[user];
    }

    // 查询用户质押的时间
    function getStakingTimestamp(address user) external view returns (uint256) {
        return stakingTimestamps[user];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
