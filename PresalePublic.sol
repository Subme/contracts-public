// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Allows to create allocations for token sale.
 */
contract PresalePublic is Ownable {
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant OWNER_PAYOUT_DELAY = 3 days;

    uint256 private _closingAllocationsRemainder;
    uint256 private _minimumAllocation;
    uint256 private _maximumAllocation;
    uint256 private _totalAllocationsLimit;
    uint256 private _totalAllocated;
    uint256 private _saleStart;
    bool private _isEveryoneAllowedToParticipate;
    bool private _wasClosed;
    bool private _wasStarted;
    mapping (address => uint256) private _allocations;
    mapping (address => bool) private _allowedParticipants;

    event SaleStarted();
    event SaleClosed();
    event Allocated(address indexed participant, uint256 allocation);

   /**
    * @dev Initializes sale contract with minimum and maximum amount that can be allocated and total allocation limit.
    * @param allowedParticipantsValue List of addresses allowed to participate.
    */
    constructor(address[] memory allowedParticipantsValue) {
        addAllowedParticipants(allowedParticipantsValue);
    }

    /**
     * @dev Extend the allowed participants list.
     * @param participantsValue List of allowed addresses to add.
     */
    function addAllowedParticipants(address[] memory participantsValue) public onlyOwner {
        unchecked {
            for (uint256 i = 0; i < participantsValue.length; ++i) {
                _allowedParticipants[participantsValue[i]] = true;
            }
        }
    }

    /**
     * @dev Setups and starts the sale.
     * @param minimumAllocationValue Minimum allocation value.
     * @param maximumAllocationValue Maximum allocation value.
     * @param totalAllocationsLimitValue Total allocations limit.
     * @param closingAllocationsRemainderValue Remaining amount of allocations allowing to close sale before reaching total allocations limit.
     */
    function startSale(uint256 minimumAllocationValue, uint256 maximumAllocationValue, uint256 totalAllocationsLimitValue, uint256 closingAllocationsRemainderValue) public onlyOwner {
        require(!_wasStarted, "PresalePublic: Sale was already started");
        require(!_wasClosed, "PresalePublic: Sale was already closed");

        _closingAllocationsRemainder = closingAllocationsRemainderValue;
        _minimumAllocation = minimumAllocationValue;
        _maximumAllocation = maximumAllocationValue;
        _totalAllocationsLimit = totalAllocationsLimitValue;
        _saleStart = block.timestamp;
        _wasStarted = true;

        emit SaleStarted();
    }

    /**
     * @dev Opens the sale to everyone.
     */
    function openSale() public payable {
        require(_wasStarted, "PresalePublic: Sale was not started yet");
        require(!_wasClosed, "PresalePublic: Sale was already closed");
        require(!_isEveryoneAllowedToParticipate, "PresalePublic: Sale was already opened to everyone");

        _isEveryoneAllowedToParticipate = true;
    }


    /**
     * @dev Allows the owner to close sale and payout all currency.
     */
    function closeSale() public onlyOwner {
        require(canCloseSale(), "PresalePublic: Cannot payout yet");

        _wasClosed = true;

        emit SaleClosed();

        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
     * @dev Allows to allocate currency for the sale.
     */
    function allocate() public payable {
        require(wasStarted(), "PresalePublic: Cannot allocate yet");
        require(areAllocationsAccepted(), "PresalePublic: Cannot allocate anymore");
        require(msg.value >= _minimumAllocation, "PresalePublic: Allocation is too small");
        require(msg.value.add(_allocations[msg.sender]) <= _maximumAllocation, "PresalePublic: Allocation is too big");
        require(canAllocate(msg.sender), "PresalePublic: Not allowed to participate");

        _totalAllocated = _totalAllocated.add(msg.value);
        require(_totalAllocated <= _totalAllocationsLimit, "PresalePublic: Allocation is too big");
        _allocations[msg.sender] = _allocations[msg.sender].add(msg.value);

        emit Allocated(msg.sender, msg.value);
    }

    /**
     * @dev Returns amount allocated from given address.
     * @param participant Address to check.
     */
    function allocation(address participant) public view returns (uint256) {
        return _allocations[participant];
    }

    /**
     * @dev Checks if allocations are still accepted.
     */
    function areAllocationsAccepted() public view returns (bool) {
        return (isActive() && (_totalAllocationsLimit.sub(_totalAllocated) >= _minimumAllocation));
    }

    /**
     * @dev Checks if given address can still allocate.
     * @param participant Address to check.
     */
    function canAllocate(address participant) public view returns (bool) {
        if (!areAllocationsAccepted() || !isAllowedToParticipate(participant)) {
            return false;
        }

        return (_allocations[participant].add(_minimumAllocation) <= _maximumAllocation);
    }

    /**
     * @dev Checks if owner can close sale and payout the currency.
     */
    function canCloseSale() public view returns (bool) {
        return isActive() && (block.timestamp >= (_saleStart.add(OWNER_PAYOUT_DELAY)) || !areAllocationsAccepted() || _closingAllocationsRemainder >= (_totalAllocationsLimit.sub(_totalAllocated)));
    }

    /**
     * @dev Returns remaining amount of allocations allowing to close sale before reaching total allocations limit.
     */
    function closingAllocationsRemainder() public view returns (uint256) {
        return _closingAllocationsRemainder;
    }

    /**
     * @dev Checks if given address is allowed to participate.
     * @param participant Address to check.
     */
    function isAllowedToParticipate(address participant) public view returns (bool) {
        return (_isEveryoneAllowedToParticipate || _allowedParticipants[participant]);
    }

    /**
     * @dev Checks if sale is active.
     */
    function isActive() public view returns (bool) {
        return (_wasStarted && !_wasClosed);
    }

    /**
     * @dev Checks if everyone is allowed to participate.
     */
    function isEveryoneAllowedToParticipate() public view returns (bool) {
        return _isEveryoneAllowedToParticipate;
    }

    /**
     * @dev Returns minimum allocation amount.
     */
    function minimumAllocation() public view returns (uint256) {
        return _minimumAllocation;
    }

    /**
     * @dev Returns maximum allocation amount.
     */
    function maximumAllocation() public view returns (uint256) {
        return _maximumAllocation;
    }

    /**
     * @dev Returns sale start timestamp.
     */
    function saleStart() public view returns (uint256) {
        return _saleStart;
    }

    /**
     * @dev Returns total allocations limit.
     */
    function totalAllocationsLimit() public view returns (uint256) {
        return _totalAllocationsLimit;
    }

    /**
     * @dev Returns allocated amount.
     */
    function totalAllocated() public view returns (uint256) {
        return _totalAllocated;
    }

    /**
     * @dev Checks if sale was already started.
     */
    function wasStarted() public view returns (bool) {
        return _wasStarted;
    }

    /**
     * @dev Checks if sale was already closed.
     */
    function wasClosed() public view returns (bool) {
        return _wasClosed;
    }

    /**
     * @dev Fallback receive method.
     */
    receive() external payable {
        allocate();
    }
}
