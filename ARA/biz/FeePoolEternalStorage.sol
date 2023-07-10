pragma solidity >=0.5.0 <0.7.0;


import "../../common/Deadline.sol";
import "../../common/MappingStorage.sol";


contract FeePoolEternalStorage is Deadline, MappingStorage {

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    /**
     * @dev Constructor.
     */
    constructor(address _feePool)
    Deadline(6 weeks)
    public
    {
        _addWhitelisted(_feePool);
    }

    /**
     * @notice Import data from FeePool.lastFeeWithdrawal
     * @dev Only callable by the contract owner, and only for 6 weeks after deployment.
     * @param accounts Array of addresses that have claimed
     * @param feePeriodIDs Array feePeriodIDs with the accounts last claim
     */
    function importFeeWithdrawalData(address[] calldata accounts, uint[] calldata feePeriodIDs)
    external
    onlyOwner
    beforeDeadline
    {
        require(accounts.length == feePeriodIDs.length, "FeePoolEternalStorage: Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            this.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, accounts[i])), feePeriodIDs[i]);
        }
    }
}