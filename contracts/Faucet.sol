// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./utils/SafeERC20.sol";

contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not a owner");
        _;
    }
}

contract Faucet is owned {
    using SafeERC20 for IERC20;
    uint256 public timeLimit;
    uint256 public withdrawalAmount;
    IERC20 public TON;
    IERC20 public TOS;
    IERC20 public USDT;
    IERC20 public USDC;

    mapping(address => mapping(IERC20 => uint256)) public lastTokenRequestTime;
    
    event WithdrawalRequest(address indexed to, IERC20 token ,uint amount);
    event Deposit(address indexed from, uint amount);

    constructor(
        address _TON,
        address _TOS,
        address _USDT,
        address _USDC,
        uint256 _timeLimit,
        uint256 _withdrawalAmount
    ) {
        TON = IERC20(_TON);
        TOS = IERC20(_TOS);
        USDT = IERC20(_USDT);
        USDC = IERC20(_USDC);
        
        timeLimit = _timeLimit;
        withdrawalAmount = _withdrawalAmount;
    }

    /*
    function requestAllTokens() external { }
    */

    function requestToken(IERC20 token) external {
        require(token == TON || token == TOS || token == USDT || token == USDC, "Token not supported by faucet");
        require(token.balanceOf(address(this)) >= withdrawalAmount, "Not eunough balance in faucet");

        uint256 lastRequest = lastTokenRequestTime[msg.sender][token];
        require(block.timestamp >= lastRequest + timeLimit, "Time limit has not passed");

        lastTokenRequestTime[msg.sender][token] = block.timestamp;
        token.safeTransfer(msg.sender, withdrawalAmount);
        emit WithdrawalRequest(msg.sender, token, withdrawalAmount);
    }

    function setTimeLimit(uint256 _timeLimit) external onlyOwner {
        timeLimit = _timeLimit;
    }

    function setWithdrawalAmount(uint256 _withdrawalAmount) external onlyOwner {
        withdrawalAmount = _withdrawalAmount;
    }

    function withdrawalAll() external onlyOwner {
        if (address(this).balance > 0) {
            payable(owner).transfer(address(this).balance);
        }

        if (TON.balanceOf(address(this)) > 0) {
            TON.safeTransfer(msg.sender, TON.balanceOf(address(this)));
        }

        if (TOS.balanceOf(address(this)) > 0) {
            TOS.safeTransfer(msg.sender, TOS.balanceOf(address(this)));
        }

        if (USDT.balanceOf(address(this)) > 0) {
            USDT.safeTransfer(msg.sender, USDT.balanceOf(address(this)));
        }

        if (USDC.balanceOf(address(this)) > 0) {
            USDC.safeTransfer(msg.sender, USDC.balanceOf(address(this)));
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}