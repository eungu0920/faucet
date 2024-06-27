// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./utils/SafeERC20.sol";

/// @title Owned Contract
/// @notice This contract sets the deployer as the owner
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

/// @title Faucet Contract
/// @notice This contract allows users to request tokens with a time limit
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

    /// @notice Initializes the contract with the given parameters
    /// @param _TON The address of the TON token
    /// @param _TOS The address of the TOS token
    /// @param _USDT The address of the USDT token
    /// @param _USDC The address of the USDC token
    /// @param _timeLimit The time limit between requests
    /// @param _withdrawalAmount The amount of tokens to withdraw per request
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

    /// @notice Requests a specific token from the faucet
    /// @param token The token to request
    function requestToken(IERC20 token) external {
        require(token == TON || token == TOS || token == USDT || token == USDC, "Token not supported by faucet");
        require(token.balanceOf(address(this)) >= withdrawalAmount, "Not eunough balance in faucet");

        uint256 lastRequest = lastTokenRequestTime[msg.sender][token];
        require(block.timestamp >= lastRequest + timeLimit, "Time limit has not passed");

        lastTokenRequestTime[msg.sender][token] = block.timestamp;
        token.safeTransfer(msg.sender, withdrawalAmount);
        emit WithdrawalRequest(msg.sender, token, withdrawalAmount);
    }

    /// @notice Sets the time limit between requests
    /// @param _timeLimit The new time limit
    function setTimeLimit(uint256 _timeLimit) external onlyOwner {
        timeLimit = _timeLimit;
    }

    /// @notice Sets the withdrawal amount per request
    /// @param _withdrawalAmount The new withdrawal amount
    function setWithdrawalAmount(uint256 _withdrawalAmount) external onlyOwner {
        withdrawalAmount = _withdrawalAmount;
    }

    /// @notice Withdraws all tokens and Ether from the faucet
    function withdrawalAll() external onlyOwner {
        if (address(this).balance > 0) {
            payable(owner).transfer(address(this).balance);
        }

        _withdrawToken(TON);
        _withdrawToken(TOS);
        _withdrawToken(USDT);
        _withdrawToken(USDC);
    }

    /// @notice Transfers ownership of the contract to a new address
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    /// @dev Internal function to withdraw a specific token
    /// @param token The token to withdraw
    function _withdrawToken(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(msg.sender, balance);
        }
    }

    /// @notice Fallback function to handle Ether deposits
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}