// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PresaleSimple is Ownable, Pausable {
    using Address for address;
    using SafeMath for uint256;

    uint256 internal immutable _minAmount;
    uint256 internal immutable _maxAmount;
    uint256 internal immutable _targetAmount;

    uint256 internal _raisedAmount;
    mapping(address => uint256) internal _allocations;

    constructor (uint256 minInitAmount, uint256 maxInitAmount, uint256 targetInitAmount) {
        _minAmount = minInitAmount;
        _maxAmount = maxInitAmount;
        _targetAmount = targetInitAmount;
    }

    receive () external payable {
        allocate();
    }

    function minAmount() public view returns (uint256) {
        return _minAmount;
    }

    function maxAmount() public view returns (uint256) {
        return _maxAmount;
    }

    function targetAmount() public view returns (uint256) {
        return _targetAmount;
    }

    function allocate() public payable whenNotPaused {
        require(_raisedAmount < targetAmount(), "Target raised. Not accepting any more payments");
        require(msg.value != 0, "Sent value cannot be 0!");
        require(msg.value >= minAmount() && msg.value <= maxAmount(), "Sent value must be within MIN<>MAX amount");
        require(_raisedAmount.add(msg.value) <= targetAmount(), "Sent value goes over max target. Please try sending lower amount");
        require(_allocations[msg.sender].add(msg.value) <= maxAmount(), "Sent value goes over max target. Please try sending lower amount");

        _raisedAmount = _raisedAmount.add(msg.value);
        _allocations[msg.sender] = _allocations[msg.sender].add(msg.value);
    }

    function withdraw() public onlyOwner {
        require(_raisedAmount >= targetAmount() || paused(), "Cannot withdraw yet");

        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function allocation(address participant) public view returns (uint256) {
        return _allocations[participant];
    }

    function pause() public whenNotPaused onlyOwner {
        super._pause();
    }

    function unpause() public whenPaused onlyOwner {
        super._unpause();
    }

    function raisedAmount() public view returns (uint256) {
        return _raisedAmount;
    }
}
