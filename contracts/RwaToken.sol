// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.2/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.2/contracts/access/AccessControl.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.2/contracts/utils/Pausable.sol";

interface ICompliance {
    function canTransfer(address from, address to, uint256 v, bytes calldata d)
        external view returns (bool, uint256);
}

contract RwaToken is ERC20, AccessControl, Pausable {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    ICompliance public compliance;

    event ForceTransfer(address indexed from, address indexed to, uint256 value, string reason);

    constructor(string memory n, string memory s, address admin, address comp)
        ERC20(n, s)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
        compliance = ICompliance(comp);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    function _update(address from, address to, uint256 value) internal override {
        require(!paused(), "paused");
        if (from != address(0) || to != address(0)) {
            (bool ok, uint256 reason) = compliance.canTransfer(from, to, value, "");
            require(ok, string(abi.encodePacked("compliance fail: ", _toStr(reason))));
        }
        super._update(from, to, value);
    }

    // Mint after KYC is set
    function mint(address to, uint256 value) external onlyRole(ISSUER_ROLE) {
        _update(address(0), to, value); // run compliance (receiver must be KYC'd)
        _mint(to, value);
    }

    function forceTransfer(address from, address to, uint256 value, string calldata reason)
        external onlyRole(ISSUER_ROLE)
    {
        _update(from, to, value);
        emit ForceTransfer(from, to, value, reason);
    }

    function _toStr(uint256 x) internal pure returns (string memory) {
        if (x == 0) return "0";
        bytes memory b; while (x != 0) { b = abi.encodePacked(uint8(48 + x % 10), b); x /= 10; }
        return string(b);
    }
}