// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzepplin/contracts/access/Ownable.sol";
import "@openzepplin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Faucet Contract
/// @notice This contract allows users to request tokens with a time limit
contract Faucet is Ownable {
    using SafeERC20 for IERC20;
    uint256 public timeLimit;
    IERC20[] public tokens;

    mapping(IERC20 => uint256) public tokenAmounts;
    mapping(address => mapping(IERC20 => uint256)) public lastTokenRequestTime;
    
    /// @notice Emitted when a withdrawal request is made
    /// @param to The address to which the tokens are sent
    /// @param token The token that is being withdrawn
    /// @param amount The amount of tokens withdrawn
    event WithdrawalRequest(address indexed to, IERC20 token ,uint amount);

    /// @notice Initializes the contract with the given parameters
    /// @param _timeLimit The time limit between requests
    constructor(uint256 _timeLimit) {        
        timeLimit = _timeLimit;        
    }

    /// @notice Requests a specific token from the faucet
    /// @param token The token to request
    function requestToken(IERC20 token) external {
        require(tokenAmounts[token] > 0, "Token not supported by faucet");
        require(token.balanceOf(address(this)) >= tokenAmounts[token], "Not eunough balance in faucet");

        uint256 lastRequest = lastTokenRequestTime[msg.sender][token];
        require(block.timestamp >= lastRequest + timeLimit, "Time limit has not passed");

        lastTokenRequestTime[msg.sender][token] = block.timestamp;
        token.safeTransfer(msg.sender, tokenAmounts[token]);
        emit WithdrawalRequest(msg.sender, token, tokenAmounts[token]);
    }

    /// @notice Sets the withdrawal amount for a specific token
    /// @param token The token to set the amount for
    /// @param amount The new withdrawal amount
    function setTokenAmount(IERC20 token, uint256 amount) external onlyOwner {
        tokenAmounts[token] = amount;

        bool tokenExists = false;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                tokenExists = true;
                break;
            }
        }

        if (!tokenExists) {
            tokens.push(token);    
        }
    }

    /// @notice Sets the time limit between requests
    /// @param _timeLimit The new time limit
    function setTimeLimit(uint256 _timeLimit) external onlyOwner {
        timeLimit = _timeLimit;
    }

    /// @notice Withdraws all tokens and Ether from the faucet
    function withdrawalAll() external onlyOwner {
        if (address(this).balance > 0) {
            payable(owner).transfer(address(this).balance);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            _withdrawToken(tokens[i]);
        }
    }

    /// @notice Transfers ownership of the contract to a new address
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        super.transferOwnership(newOwner);
    }

    /// @dev Internal function to withdraw a specific token
    /// @param token The token to withdraw
    function _withdrawToken(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(owner(), balance);
        }
    }

    /// @notice Fallback function to handle Ether deposits
    receive() external payable {
        revert("Ether deposits not allowed");
    }
}