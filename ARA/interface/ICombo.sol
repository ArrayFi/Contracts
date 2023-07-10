pragma solidity >=0.5.0 <0.7.0;


interface ICombo {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function currencyKey() external view returns (bytes32);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function foundryToTransferFrom(address from, address to, uint value) external returns (bool);
}
