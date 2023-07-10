pragma solidity >=0.5.0 <0.7.0;

interface IRelationship {
    /**
    * return false if user already binded，else return true or bind to proxy then return true
    */
    function verifyAndBind(address user, address proxy) external returns (bool);

    function getProxyDetail(address user) external view returns (uint, address, uint256);

    function getProxyDetail(uint proxyId) external view returns (uint, address, uint256);

    /**
    * return true when user binded to proxy
    */
    function isBinded(address user, address proxy) external view returns (bool);
    function isProxy(address proxy) external view returns (bool);

    function getAllProxyBindings(address proxy) external view returns(address[] memory);
}