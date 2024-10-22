// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FUCAI is ERC20, Ownable {
    // 定义每个用户的质押余额（以 ETH 计）
    mapping(address => uint256) public ethBalances;

    // 定义每个用户的质押时间
    mapping(address => uint256) public stakingTimestamps;

    // 总质押量（以 ETH 计）
    uint256 public totalEthStaked;

    // 奖励等待时间（以秒计）
    uint256 public constant REWARD_DURATION = 30 days;

    // 奖励的上限，最多领取 500 枚 FUCAI
    uint256 public constant MAX_REWARD = 500 * (10 ** 18); // 500 枚 FUCAI

    // 奖励领取的截止时间，2024年12月21日的时间戳
    uint256 public constant rewardEndTime = 1734739200; // 2024年12月21日 00:00:00 UTC

    // 事件定义
    event StakedETH(address indexed user, uint256 amount);
    event UnstakedETH(address indexed user, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount); // 新增奖励发放事件

    // 构造函数
    constructor(uint256 initialSupply) ERC20("FUCAI", "FCB") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    // 质押 ETH 并铸造相应数量的 FUCAI 代币
    function stake() external payable {
        require(msg.value > 0, "You must stake a positive amount");

        ethBalances[msg.sender] += msg.value;
        totalEthStaked += msg.value;

        // 记录质押时间
        stakingTimestamps[msg.sender] = block.timestamp;
        // 1 ETH = 50 FUCAI
        uint256 tokensToMint = msg.value * 50;
        _mint(msg.sender, tokensToMint);

        emit StakedETH(msg.sender, msg.value);
        emit TokensMinted(msg.sender, tokensToMint);
    }

    // 解除质押并返还 ETH
    function unstake(uint256 amount) external {
        require(ethBalances[msg.sender] >= amount, "Insufficient staked ETH balance");

        ethBalances[msg.sender] -= amount;
        totalEthStaked -= amount;

        uint256 tokensToBurn = amount * 50;
        _burn(msg.sender, tokensToBurn);

        // payable(msg.sender).transfer(amount);
        // 使用 call 方法进行 ETH 转账以提高安全性
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit UnstakedETH(msg.sender, amount);
        emit TokensBurned(msg.sender, tokensToBurn);
    }

    // 领取奖励
    function claimReward() external {
        require(ethBalances[msg.sender] > 0, "No ETH staked");
        require(block.timestamp >= stakingTimestamps[msg.sender] + REWARD_DURATION, "Staking period not complete");
        require(block.timestamp <= rewardEndTime, "Reward claim period has ended"); // 确保在奖励领取的时间内

        // 奖励计算，基于用户质押的 ETH。假设每 1 ETH 对应 50 FUCAI 的奖励
        uint256 reward = ethBalances[msg.sender] * 50;

        // 限制奖励上限为 500 FUCAI
        if (reward > MAX_REWARD) {
            reward = MAX_REWARD;
        }

        // 防止重复领取奖励，更新质押时间以确保用户重新开始一个新的质押周期
        stakingTimestamps[msg.sender] = block.timestamp;

        // 铸造奖励代币
        _mint(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
        emit TokensMinted(msg.sender, reward);
    }

    // 合约拥有者铸造更多代币
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // 合约拥有者销毁代币
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    // 查询用户的质押 ETH 余额
    function getStakedBalance(address user) external view returns (uint256) {
        return ethBalances[user];
    }

    // 查询用户质押的时间
    function getStakingTimestamp(address user) external view returns (uint256) {
        return stakingTimestamps[user];
    }
}
