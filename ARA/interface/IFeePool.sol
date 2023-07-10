pragma solidity >=0.5.0 <0.7.0;


contract IFeePool {
    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex) external;
}
