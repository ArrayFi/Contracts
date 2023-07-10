pragma solidity >=0.5.0 <0.7.0;


import "../../common/Storage.sol";


contract RewardEscrowStorage is Storage {
    mapping(address => Escrow[]) private _vestingSchedules;
    mapping(address => uint256) private _totalDepositedBalance;
    mapping(address => uint256) private _totalWithdrawnBalance;
    uint256 private _totalBalance;

    struct Escrow {
        uint256 timestamp;
        uint256 amount;
    }

    constructor() public {}

    function getVestingLength(address account) public view returns (uint256) {
        return _vestingSchedules[account].length;
    }

    function getVestingEntry(address account, uint256 index) public view returns (uint256, uint256) {
        Escrow memory escrow = _vestingSchedules[account][index];
        return (escrow.timestamp, escrow.amount);
    }

    function getVestingEntries(address account) public view returns (uint256[1460] memory) {
        uint256[1460] memory entries;

        uint256 length = getVestingLength(account);
        for (uint256 index = 0; index < length && index < 730; index++) {
            (uint256 timestamp, uint256 amount) = getVestingEntry(account, index);
            entries[index * 2] = timestamp;
            entries[index * 2 + 1] = amount;
        }

        return entries;
    }

    function getVestingTime(address account, uint256 index) public view returns (uint256) {
        (uint256 timestamp,) = getVestingEntry(account, index);
        return timestamp;
    }

    function getVestingAmount(address account, uint256 index) public view returns (uint256) {
        (, uint256 amount) = getVestingEntry(account, index);
        return amount;
    }

    function getNextVestingIndex(address account) public view returns (uint256) {
        uint256 length = getVestingLength(account);

        for (uint256 index = 0; index < length; index++) {
            if (getVestingTime(account, index) != 0) {
                return index;
            }
        }

        return length;
    }

    function getNextVestingEntry(address account) public view returns (uint256, uint256) {
        uint256 index = getNextVestingIndex(account);

        if (index == getVestingLength(account)) {
            return (uint256(0), uint256(0));
        }

        return getVestingEntry(account, index);
    }

    function getNextVestingTime(address account) public view returns (uint256) {
        (uint256 timestamp,) = getNextVestingEntry(account);
        return timestamp;
    }

    function getNextVestingAmount(address account) public view returns (uint256) {
        (, uint256 amount) = getNextVestingEntry(account);
        return amount;
    }

    function deposited(address account) public view returns (uint256) {
        return _totalDepositedBalance[account];
    }

    function withdrawn(address account) public view returns (uint256) {
        return _totalWithdrawnBalance[account];
    }

    function totalBalance() public view returns (uint256) {
        return _totalBalance;
    }

    function setTotalBalance(uint256 newTotalBalance) public onlyWhitelisted {
        _totalBalance = newTotalBalance;
    }

    function addVestingSchedule(address account, uint256 timestamp, uint256 amount) public onlyWhitelisted {
        Escrow memory escrow = Escrow(timestamp, amount);
        _vestingSchedules[account].push(escrow);
    }

    function delVestingSchedule(address account, uint256 index) public onlyWhitelisted {
        Escrow memory escrow = Escrow(uint256(0), uint256(0));
        _vestingSchedules[account][index] = escrow;
    }

    function setTotalDepositedBalance(address account, uint256 newTotalDepositedBalance) public onlyWhitelisted {
        _totalDepositedBalance[account] = newTotalDepositedBalance;
    }

    function setTotalWithdrawnBalance(address account, uint256 newTotalWithdrawnBalance) public onlyWhitelisted {
        _totalWithdrawnBalance[account] = newTotalWithdrawnBalance;
    }
}
