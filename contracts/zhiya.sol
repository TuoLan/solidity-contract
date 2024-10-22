// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LiquidStaking {
    // 定义每个质押者的质押余额
    mapping(address => uint256) public balances;
    
    // 代表质押权益的流动性代币
    mapping(address => uint256) public liquidityTokens;
    
    // 总质押量
    uint256 public totalStaked;
    
    // 总发行的流动性代币数量
    uint256 public totalLiquidityTokens;

    // 事件
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event LiquidityTokenMinted(address indexed user, uint256 amount);
    event LiquidityTokenBurned(address indexed user, uint256 amount);

    // 质押 ETH 并获取相应数量的流动性代币
    function stake() external payable {
        require(msg.value > 0, "You must stake a positive amount");

        // 更新质押者的余额和总质押量
        balances[msg.sender] += msg.value;
        totalStaked += msg.value;

        // 计算流动性代币的数量，假设 1:1 比例
        uint256 liquidityAmount = msg.value;
        
        // 为用户铸造流动性代币
        liquidityTokens[msg.sender] += liquidityAmount;
        totalLiquidityTokens += liquidityAmount;

        emit Staked(msg.sender, msg.value);
        emit LiquidityTokenMinted(msg.sender, liquidityAmount);
    }

    // 解除质押并销毁相应数量的流动性代币
    function unstake(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient staked balance");
        require(liquidityTokens[msg.sender] >= amount, "Insufficient liquidity tokens");

        // 更新质押者的余额和总质押量
        balances[msg.sender] -= amount;
        totalStaked -= amount;

        // 销毁用户的流动性代币
        liquidityTokens[msg.sender] -= amount;
        totalLiquidityTokens -= amount;

        // 将 ETH 退还给用户
        payable(msg.sender).transfer(amount);

        emit Unstaked(msg.sender, amount);
        emit LiquidityTokenBurned(msg.sender, amount);
    }

    // 查询用户的质押余额
    function getStakedBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // 查询用户的流动性代币余额
    function getLiquidityTokenBalance(address user) external view returns (uint256) {
        return liquidityTokens[user];
    }
}
