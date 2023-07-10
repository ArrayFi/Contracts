pragma solidity >=0.5.0 <0.7.0;


import "./Proxy.sol";
import "./Ownable.sol";


contract Proxyable is Ownable {
    Proxy private _proxy;
    Proxy private _delegate;
    address public caller;

    constructor() public {}

    function proxy() public view returns (Proxy) {
        return _proxy;
    }

    function setProxy(Proxy newProxy) public onlyOwner {
        emit ProxyTransferred(_proxy, newProxy);
        _proxy = newProxy;
    }

    function delegate() public view returns (Proxy) {
        return _delegate;
    }

    function setDelegate(Proxy newDelegate) public onlyOwner {
        _delegate = newDelegate;
    }

    function setCaller(address newCaller) public onlyProxy {
        caller = newCaller;
    }

    modifier onlyProxy() {
        require(Proxy(msg.sender) == _proxy || Proxy(msg.sender) == _delegate, "Proxyable: caller is not the proxy");
        _;
    }

    modifier optionalProxy() {
        if (Proxy(msg.sender) != _proxy && Proxy(msg.sender) != _delegate && caller != msg.sender) {
            caller = msg.sender;
        }
        _;
    }

    modifier optionalProxyAndOnlyOwner() {
        if (Proxy(msg.sender) != _proxy && Proxy(msg.sender) != _delegate && caller != msg.sender) {
            caller = msg.sender;
        }
        require(isOwner(caller), "Proxyable: caller is not the owner");
        _;
    }

    event ProxyTransferred(Proxy indexed previousProxy, Proxy indexed newProxy);
}
