// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title TokenBurner
 * @dev Burner for BEP20 compatible token.
 */
contract TokenBurner is Ownable {
    address private _token;

    event TokensBurned(uint256 amount);

    /**
     * @dev Burns given amount of tokens.
     * @param amount Amount of tokens to burn.
     */
    function burn(uint256 amount) external onlyOwner {
        require(amount <= balance(), "TokenBurner: Attempting to burn more tokens than possible");

        ERC20Burnable(_token).burn(amount);

        emit TokensBurned(amount);
    }

    /**
     * @dev Sets token address.
     * @param tokenValue Token address.
     */
    function setToken(address tokenValue) public onlyOwner {
        require(_token == address(0), "TokenBurner: Token address already set");
        _token = tokenValue;
    }

    /**
     * @dev Returns token address.
     */
    function token() public view returns (address) {
        return _token;
    }

    /**
     * @dev Returns current token balance.
     */
    function balance() public view returns (uint256) {
        return ERC20Burnable(_token).balanceOf(address(this));
    }
}
