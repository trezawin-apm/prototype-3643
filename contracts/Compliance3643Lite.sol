// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Lightweight interface to the Identity Registry.
 */
interface IIdentityRegistry {
    function isVerified(address) external view returns (bool);
    function isBlacklisted(address) external view returns (bool);
    function jurisdictionOf(address) external view returns (bytes2);
    function investorTypeOf(address) external view returns (uint8);
}

/**
 * Deterministic compliance checks (ERC-3643-style).
 * On-chain logic only; mirror the same policy off-chain for surveillance.
 */
contract Compliance3643Lite {
    IIdentityRegistry public immutable reg;

    // policy parameters
    mapping(bytes2 => bool) public allowedJuris;
    mapping(uint8  => bool) public allowedInvestorType;
    bool public disallowBlacklisted = true;

    // Reason codes (compact & loggable)
    uint256 constant OK           = 0;
    uint256 constant ERR_SND_KYC  = 1001;
    uint256 constant ERR_RCV_KYC  = 1002;
    uint256 constant ERR_BLACK    = 1003;
    uint256 constant ERR_JURIS    = 1004;
    uint256 constant ERR_INVTYPE  = 1005;

    event RulesUpdated(bytes32 rulesHash, string uri);

    constructor(address registry, bytes2[] memory juris, uint8[] memory invTypes) {
        reg = IIdentityRegistry(registry);
        for (uint i = 0; i < juris.length; i++) {
            allowedJuris[juris[i]] = true;
        }
        for (uint i = 0; i < invTypes.length; i++) {
            allowedInvestorType[invTypes[i]] = true;
        }
    }

    function canTransfer(address from, address to, uint256, bytes calldata)
        external view returns (bool ok, uint256 reason)
    {
        if (from != address(0)) {
            if (!reg.isVerified(from)) return (false, ERR_SND_KYC);
            if (disallowBlacklisted && reg.isBlacklisted(from)) return (false, ERR_BLACK);
            if (!allowedJuris[reg.jurisdictionOf(from)]) return (false, ERR_JURIS);
            if (!allowedInvestorType[reg.investorTypeOf(from)]) return (false, ERR_INVTYPE);
        }
        if (to != address(0)) {
            if (!reg.isVerified(to)) return (false, ERR_RCV_KYC);
            if (disallowBlacklisted && reg.isBlacklisted(to)) return (false, ERR_BLACK);
            if (!allowedJuris[reg.jurisdictionOf(to)]) return (false, ERR_JURIS);
            if (!allowedInvestorType[reg.investorTypeOf(to)]) return (false, ERR_INVTYPE);
        }
        return (true, OK);
    }
}