pragma solidity >=0.5.0 <0.7.0;


interface IRewardEscrow {
    function deposited(address account) external view returns (uint256);

    function withdrawn(address account) external view returns (uint256);

    function withdrawAble(address account) external view returns (uint256);

    function deposit(address account, uint256 amount) external;

    function withdraw(address account) external returns (uint256);
}
