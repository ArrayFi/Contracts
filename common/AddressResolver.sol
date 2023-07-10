pragma solidity >=0.5.0 <0.7.0;


import "./Resolver.sol";


/**
 * Resolver Utility
 */
contract AddressResolver is Resolver {
    Resolver private _resolver;

    constructor() internal {}

    function resolver() public view returns (Resolver) {
        return _resolver;
    }

    function setResolver(address newResolver) public onlyOwner {
        emit ResolverTransferred(_resolver, Resolver(newResolver));
        _resolver = Resolver(newResolver);
    }


    event ResolverTransferred(Resolver indexed previousResolver, Resolver indexed newResolver);
}
