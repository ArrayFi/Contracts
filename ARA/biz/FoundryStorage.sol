pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../../common/Deadline.sol";
import "../../common/Storage.sol";
import "../common/MixinResolver.sol";
import "./Foundry.sol";


/**
 * @title Foundry Storage
 * @notice Stores issuance information and preferred currency information of the Foundry contract.
 */
contract FoundryStorage is Deadline, Storage, MixinResolver {
    using SafeMath for uint;

    // Issued combo balances for individual fee entitlements and exit price calculations
    mapping(address => uint) public issuanceData;

    uint UNIT = 10 ** 18;

    // A quantity of combos greater than this ratio
    // may not be issued against a given value of Foundry.
    uint public issuanceRatio = UNIT / 4;
    // No more combos may be issued than the value of Foundry backing them.
    uint MAX_ISSUANCE_RATIO = UNIT;

    address[] public allMortgaged;
    mapping(address => bool) private mortgagedAccounts;


    /**
     * @dev Constructor
     */
    constructor()
    Deadline(1 weeks)
    public
    {}

    /* ========== SETTERS ========== */

    /**
     * @notice add debt issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to set the data for.
     * @param amount The debt for this address.
     */
    function addIssuanceData(address account, uint256 amount)
    external
    onlyWhitelisted
    {
        _addToDebtRegister(account, amount);
    }

    /**
     * @notice remove debt issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to set the data for.
     * @param amount The debt for this address.
     */
    function removeIssuanceData(address account, uint256 amount)
    external
    onlyWhitelisted
    {
        _removeToDebtRegister(account, amount);
    }

    /**
     * @notice Clear issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to clear the data for.
     */
    function clearIssuanceData(address account)
    external
    onlyWhitelisted
    {
        delete issuanceData[account];
    }


    /**
     * @notice Import issuer data from the old Foundry contract before multi currency
     * @dev Only callable by the contract owner, and only for 1 week after deployment.
     */
    function importIssuerData(address[] calldata accounts, uint[] calldata USDRAmounts)
    external
    onlyOwner
    beforeDeadline
    {
        require(accounts.length == USDRAmounts.length, "FoundryStorage: Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            _addToDebtRegister(accounts[i], USDRAmounts[i]);
        }
    }

    /**
     * @notice Import issuer data from the old Foundry contract before multi currency
     * @dev Only used from importIssuerData above, meant to be disposable
     * @param account The address to add debt.
     */
    function _addToDebtRegister(address account, uint amount)
    internal
    {
        issuanceData[account] = issuanceData[account].add(amount);

        emit UserDebtChange(account, issuanceData[account]);
    }

    /**
     * @notice Import issuer data from the old Foundry contract before multi currency
     * @dev Only used from importIssuerData above, meant to be disposable
     * @param account The address to remove debt.
     */
    function _removeToDebtRegister(address account, uint amount)
    internal
    {
        issuanceData[account] = issuanceData[account].sub(amount);

        emit UserDebtChange(account, issuanceData[account]);
    }

    /**
     * @notice Record address who mortgage for the first time
     * @dev Only the associated contract may call this.
     * @param account The decentral address to record.
     */
    function recordMortgagedAccount(address account)
    external
    onlyWhitelisted
    {
        if(mortgagedAccounts[account]){
            return;
        }
        allMortgaged.push(account);
        mortgagedAccounts[account] = true;
    }

    /* ========== VIEWS ========== */

    function getAllMortgaged()
    external
    view
    returns (address[] memory)
    {
        address[] memory result = new address[](allMortgaged.length);
        for(uint index = 0; index < allMortgaged.length; index++){
            result[index] = allMortgaged[index];
        }
        return result;
    }

    /**
     * @notice Query whether an account has mortgaged
     * @param account The address to query for
     */
    function hasMortgaged(address account)
    external
    view
    returns (bool)
    {
        return mortgagedAccounts[account];
    }

    event UserDebtChange(address account, uint256 amount);
}