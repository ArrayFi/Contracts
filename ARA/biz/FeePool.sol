pragma solidity >=0.5.0 <0.7.0;


import "../../library/SafeMath.sol";
import "../../common/ApprovalStorage.sol";
import "../../common/Deadline.sol";
import "../../common/Proxyable.sol";
import "../../library/Address.sol";
import "../interface/IFoundry.sol";
import "../interface/ICombo.sol";
import "../interface/IFoundryEscrow.sol";
import "../interface/IFoundryStorage.sol";
import "./FeePoolStorage.sol";
import "./FeePoolEternalStorage.sol";
import "../common/MixinResolver.sol";


contract FeePool is Deadline, Proxyable, MixinResolver {

    using SafeMath for uint;
    using Address for address;

    IFoundryStorage public foundryStorage;
    IFoundryEscrow public rewardEscrow;
    FeePoolEternalStorage public feePoolEternalStorage;

    // The address with the authority to distribute rewards.
    address public rewardsAuthority;

    // The address to the FeePoolStorage Contract.
    FeePoolStorage public feePoolStorage;


    /* ========== ETERNAL STORAGE CONSTANTS ========== */

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    constructor()
    Deadline(2 weeks)
    public
    {}

    // function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex)
    // external
    // onlyFoundry
    // {
    //     feePoolStorage.appendAccountIssuanceRecord(account, debtRatio, debtEntryIndex, _recentFeePeriodsStorage(0).startingDebtIndex);

    //     emitIssuanceDebtRatioEntry(account, debtRatio, debtEntryIndex, _recentFeePeriodsStorage(0).startingDebtIndex);
    // }

    function setRewardEscrow(IFoundryEscrow _rewardEscrow)
    external
    optionalProxyAndOnlyOwner
    {
        rewardEscrow = _rewardEscrow;
    }


    function setFoundryStorage(IFoundryStorage _foundryStorage)
    external
    optionalProxyAndOnlyOwner
    {
        foundryStorage = _foundryStorage;
    }

    /**
     * @notice Set the address of the contract responsible for distributing rewards
     */
    function setRewardsAuthority(address _rewardsAuthority)
    external
    optionalProxyAndOnlyOwner
    {
        rewardsAuthority = _rewardsAuthority;
    }

    /**
     * @notice Set the address of the contract for feePool state
     */
    function setFeePoolStorage(FeePoolStorage _feePoolStorage)
    external
    optionalProxyAndOnlyOwner
    {
        feePoolStorage = _feePoolStorage;
    }

    function setFeePoolEternalStorage(FeePoolEternalStorage _feePoolEternalStorage)
    external
    optionalProxyAndOnlyOwner
    {
        feePoolEternalStorage = _feePoolEternalStorage;
    }

    /**
    * @notice Owner can escrow. Owner to send the tokens to the RewardEscrow
    * @param account Address to escrow tokens for
    * @param quantity Amount of tokens to escrow
    */
    function appendVestingEntry(address account, uint quantity)
    public
    optionalProxyAndOnlyOwner
    {
        // Transfer token from caller to the Reward Escrow
        foundry().transferFrom(caller, address(rewardEscrow), quantity);

        // Create Vesting Entry
        rewardEscrow.appendVestingEntry(account, quantity);
    }

    /* ========== Modifiers ========== */

    modifier onlyFoundry
    {
        require(msg.sender == address(foundry()), "FeePool: Only foundry Authorised");
        _;
    }
}
