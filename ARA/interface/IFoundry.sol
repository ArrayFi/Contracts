pragma solidity >=0.5.0 <0.7.0;


import "./IFoundryStorage.sol";
import "./ICombo.sol";
import "./IFoundryEscrow.sol";
import "./IFeePool.sol";
import "./IExchangeRates.sol";

contract IFoundry {

    // ========== PUBLIC STATE VARIABLES ==========

    IFeePool public feePool;
    IFoundryEscrow public escrow;
    IFoundryEscrow public rewardEscrow;
    IFoundryStorage public foundryStorage;
    IExchangeRates public exchangeRates;

    uint public totalSupply;
        
    mapping(bytes32 => ICombo) public combos;

    // ========== PUBLIC FUNCTIONS ==========

    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey) external view returns (uint);

    function debtBalanceOf(address issuer) external view returns (uint);

    function availableCombos(uint index) external view returns (ICombo);

    function flux(address sender, address recipient, uint256 amount) external;
    function distribute(uint256 amount) external;

    function issueCombos(address account, address sender, uint amount) external;
    function issueMaxCombos(address account, address sender) external returns (uint256);
    function burnCombos(address account, address sender, uint amount) external returns (uint);
    function burnAllCombos(address account, address sender) external returns (uint256);
}
