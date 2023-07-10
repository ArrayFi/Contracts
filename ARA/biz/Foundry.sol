pragma solidity >=0.5.0 <0.7.0;


import "../common/ExternStorage.sol";
import "../../erc20/ERC20Storage.sol";
import "../../library/Address.sol";
import "./FoundryStorage.sol";
import "../interface/ICombo.sol";
import "../interface/IRewardEscrow.sol";
import "../common/MixinResolver.sol";

/**
 * @title Foundry ERC20 contract.
 * @notice The Foundry contracts not only facilitates transfers, exchanges, and tracks balances,
 * but it also computes the quantity of fees each Foundry holder is entitled to.
 */
contract Foundry is MixinResolver, ExternStorage {
    using Address for address;

    // ========== STATE VARIABLES ==========

    // Available Synths which can be used with the system
    ICombo[] public availableCombos;
    mapping(bytes32 => ICombo) public combos;
    mapping(address => bytes32) public combosByAddress;

    FoundryStorage public foundryStorage;

    uint private UNIT = 10 ** 18;

    string constant TOKEN_NAME = "Foundry Network Token";
    string constant TOKEN_SYMBOL = "custom";
    uint8 constant DECIMALS = 18;

    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor
     */
    constructor()
        ExternStorage(TOKEN_NAME, TOKEN_SYMBOL, DECIMALS)
        public
    {}
    // ========== SETTERS ========== */


    function setFoundryStorage(FoundryStorage _foundryStorage)
        external
        optionalProxyAndOnlyOwner
    {
        foundryStorage = _foundryStorage;
    }

    /**
     * @notice Add an associated Combo contract to the Foundry system
     * @dev Only the contract owner may call this.
     */
    function addCombo(ICombo combo)
        external
        optionalProxyAndOnlyOwner
    {
        bytes32 currencyKey = combo.currencyKey();
        address comboAddress = address(combo);
        require(combos[currencyKey] == ICombo(0), "Foundry: Combo already exists");
        require(combosByAddress[comboAddress] == bytes32(0), "Foundry: Combo address already exists");
        availableCombos.push(combo);
        combos[currencyKey] = combo;
        combosByAddress[comboAddress] = currencyKey;
    }

    /**
     * @notice Remove an associated Combo contract from the Foundry system
     * @dev Only the contract owner may call this.
     */
    function removeCombo(bytes32 currencyKey)
        external
        optionalProxyAndOnlyOwner
    {
        require(address(combos[currencyKey]) != address(0), "Foundry: Combo does not exist");
        require(combos[currencyKey].totalSupply() == 0, "Foundry: Combo supply exists");
        require(currencyKey != "USDR", "Foundry: Cannot remove USDR");

        // Save the address we're removing for emitting the event at the end.
        address comboToRemove = address(combos[currencyKey]);

        // Remove the combo from the availableCombos array.
        for (uint i = 0; i < availableCombos.length; i++) {
            if (address(availableCombos[i]) == comboToRemove) {
                delete availableCombos[i];
                availableCombos[i] = availableCombos[availableCombos.length - 1];

                // Decrease the size of the array by one.
                availableCombos.length--;

                break;
            }
        }

        // And remove it from the combos mapping
        delete combosByAddress[address(combos[currencyKey])];
        delete combos[currencyKey];

    }

    // ========== VIEWS ==========

    /**
     * @notice A function that lets you easily convert an amount in a source currency to an amount in the destination currency
     * @param sourceCurrencyKey The currency the amount is specified in
     * @param sourceAmount The source amount, specified in UNIT base
     * @param destinationCurrencyKey The destination currency
     */
    function effectiveValue(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey)
        public
        view
        returns (uint)
    {
        if (sourceCurrencyKey == destinationCurrencyKey || sourceAmount == 0) {
            return sourceAmount;
        }
        return rates().ratio(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
    }

    /**
     * @notice Returns the currencyKeys of availableCombos for rate checking
     */
    function availableCurrencyKeys()
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory currencyKeys = new bytes32[](availableCombos.length);

        for (uint i = 0; i < availableCombos.length; i++) {
            currencyKeys[i] = combosByAddress[address(availableCombos[i])];
        }

        return currencyKeys;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    /**
     * @notice ERC20 transfer function for ARA.
     */
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        foundryExtend().flux(msg.sender, to, value);
        return true;
    }

     /**
     * @notice ERC20 transferFrom function for ARA.
     */
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        return foundryExtend().transferFrom(from, to, value);
    }

    /**
     * @notice Function that registers new combo as they are issued. Calculate delta to append to FoundryStorage.
     * @dev Only internal calls from Foundry address.
     * @param currencyKey The currency to register combos in, for example sUSD or sAUD
     * @param amount The amount of combos to register with a base of UNIT
     */
    function _addToDebtRegister(address account, bytes32 currencyKey, uint amount)
        internal
    {
        // What is the value of the requested debt in USDRs?
        uint usdrValue = effectiveValue(currencyKey, amount, "USDR");

        // Save the debt entry parameters
        foundryStorage.addIssuanceData(account, usdrValue);
    }

    /**
     * @notice Issue combos against the sender's ARA.
     * @dev Issuance is only allowed if the foundry price isn't stale. Amount should be larger than 0.
     * @param amount The amount of combos you wish to issue with a base of UNIT
     */
    function issueCombos(address account, address sender, uint amount)
        public
        onlyFoundryExtend
        // No need to check if price is stale, as it is checked in issuableCombos.
    {
        bytes32 currencyKey = "USDR";

        require(amount <= remainingIssuableCombos(account, currencyKey), "Foundry: Amount too large");

        // Keep track of the debt they're about to create
        _addToDebtRegister(account, currencyKey, amount);

        // Create their combos
        combos[currencyKey].issue(sender, amount);

        emit IssueCombo(account, sender, amount);
    }

    /**
     * @notice Issue the maximum amount of Synths possible against the sender's ARA.
     * @dev Issuance is only allowed if the Foundry price isn't stale.
     */
    function issueMaxCombos(address account, address sender)
        external
        onlyFoundryExtend
        returns (uint256)
    {
        bytes32 currencyKey = "USDR";

        // Figure out the maximum we can issue in that currency
        uint maxIssuable = remainingIssuableCombos(account, currencyKey);

        // Keep track of the debt they're about to create
        _addToDebtRegister(account, currencyKey, maxIssuable);

        // Create their combos
        combos[currencyKey].issue(sender, maxIssuable);

        emit IssueCombo(account, sender, maxIssuable);

        return maxIssuable;
    }

    /**
     * @notice Burn combos to clear issued combos/free ARA.
     * @param amount The amount (in UNIT base) you wish to burn
     * @dev The amount to burn is debased to USDR's
     */
    function burnCombos(address account, address sender, uint amount)
        external
        onlyFoundryExtend
        returns (uint)
        // No need to check for stale rates as effectiveValue checks rates
    {
        return _internalBurnCombos(account, sender, amount);
    }

    function burnAllCombos(address account, address sender)
        external
        onlyFoundryExtend
    {
        _internalBurnCombos(account, sender, combos["USDR"].balanceOf(account));
    }

    function _internalBurnCombos(address account, address sender, uint amount) internal returns (uint){
        bytes32 currencyKey = "USDR";

        // How much debt do they have?
        uint debtToRemove = effectiveValue(currencyKey, amount, "USDR");
        uint existingDebt = debtBalanceOf(account);

        require(existingDebt > 0, "Foundry: No debt to forgive");

        // If they're trying to burn more debt than they actually owe, rather than fail the transaction, let's just
        // clear their debt and leave them be.
        uint amountToRemove = existingDebt < debtToRemove ? existingDebt : debtToRemove;

        // Remove their debt from the ledger
        _removeFromDebtRegister(account, amountToRemove);

        uint amountToBurn = existingDebt < amount ? existingDebt : amount;

        // combo.burn does a safe subtraction on balance (so it will revert if there are not enough combos).
        combos[currencyKey].burn(sender, amountToBurn);

        emit BurnCombo(sender, amountToBurn);
        return amountToBurn;
    }

    /**
     * @notice Remove a debt position from the register
     * @param amount The amount remove debt in USDRs
     */
    function _removeFromDebtRegister(address account, uint amount)
        internal
    {
        uint debtToRemove = amount;

        foundryStorage.removeIssuanceData(account, amount);
    }

    // ========== Issuance/Burning ==========

    /**
     * @notice The maximum combos an issuer can issue against their total foundry quantity, priced in USDRs.
     * This ignores any already issued combos, and is purely giving you the maximimum amount the user can issue.
     */
    function maxIssuableCombos(address issuer, bytes32 currencyKey)
        public
        view
        // We don't need to check stale rates here as effectiveValue will do it for us.
        returns (uint)
    {
        // What is the value of their ARA balance in the destination currency?
        uint destinationValue = effectiveValue("ARA", foundryExtend().araBalanceOf(issuer), currencyKey);

        // They're allowed to issue up to issuanceRatio of that value
        return destinationValue.wmul(foundryStorage.issuanceRatio());
    }

    /**
     * @notice If a user issues combos backed by ARA in their wallet, the ARA become locked. This function
     * will tell you how many combos a user has to give back to the system in order to unlock their original
     * debt position. This is priced in whichever combo is passed in as a currency key, e.g. you can price
     * the debt in USDR, or any other combo you wish.
     */
    function debtBalanceOf(address issuer)
        public
        view
        // Don't need to check for stale rates here because totalIssuedCombos will do it for us
        returns (uint)
    {
        return foundryStorage.issuanceData(issuer);
    }

    function estimateIssueCost(uint amount) public view returns (uint256) {
        uint256 priceRatio = uint256(effectiveValue("USDR", amount, "ARA"));//unit * ara price/ usdr price
        return priceRatio.wmulRound(UNIT).wdivRound(foundryStorage.issuanceRatio());
    }

    function mortgageForIssue(address account) public view returns (uint256) {
        uint256 debt = debtBalanceOf(account);
        uint256 priceRatio = uint256(effectiveValue("USDR", debt, "ARA"));//unit * ara price/ usdr price
        return priceRatio.wmulRound(UNIT).wdivRound(foundryStorage.issuanceRatio());
    }

    function debtBalanceOfProxy(address proxy) public view returns (uint256) {
        uint256 totalDebt = debtBalanceOf(proxy);
        address[] memory bindings = relationship().getAllProxyBindings(proxy);
        for(uint index = 0; index < bindings.length; index ++){
            totalDebt = totalDebt.add(debtBalanceOf(bindings[index]));
        }
        return totalDebt;
    }

    /**
     * @notice The remaining combos an issuer can issue against their total foundry balance.
     * @param issuer The account that intends to issue
     * @param currencyKey The currency to price issuable value in
     */
    function remainingIssuableCombos(address issuer, bytes32 currencyKey)
        public
        view
        // Don't need to check for combo existing or stale rates because maxIssuableCombos will do it for us.
        returns (uint)
    {
        uint alreadyIssued = debtBalanceOf(issuer);
        uint max = maxIssuableCombos(issuer, currencyKey);

        if (alreadyIssued >= max) {
            return 0;
        } else {
            return max.sub(alreadyIssued);
        }
    }


    function distribute(uint256 amount) public onlyMortgage {
        distribution().distribute(amount);
    }

    function balanceOf(address account) public view returns (uint) {
        return mortgage().balanceOf(account);
    }

    // function allMortgaged() public view returns (address[] memory) {
    //     return foundryStorage.getAllMortgaged();
    // }

    // ========== MODIFIERS ==========

    modifier onlyFoundryExtend() {
        require(msg.sender == address(foundryExtend()), "Foundry: Only foundryExtend allowed");
        _;
    }

    modifier onlyMortgage() {
        require(msg.sender == address(mortgage()), "Foundry: Only mortgage allowed");
        _;
    }

    modifier onlyPrivatePlacement() {
        require(msg.sender == address(privatePlacement()), "Foundry: Only privatePlacement allowed");
        _;
    }

    // ========== EVENTS ==========
    event IssueCombo(address account, address sender, uint256 amount);
    event BurnCombo(address account, uint256 amount);
}
