// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IIdentityRegistry2 {
    function isVerified(address) external view returns (bool);
    function isBlacklisted(address) external view returns (bool);
    function jurisdictionOf(address) external view returns (bytes2);
    function investorTypeOf(address) external view returns (uint8);
}

contract Compliance_Bug_NoReceiverKYC {
    IIdentityRegistry2 public immutable reg;
    mapping(bytes2 => bool) public allowedJuris;
    mapping(uint8  => bool) public allowedInvestorType;
    bool public disallowBlacklisted = true;

    uint256 constant OK=0;
    uint256 constant ERR_SND_KYC=1001;
    uint256 constant ERR_BLACK=1003;
    uint256 constant ERR_JURIS=1004;
    uint256 constant ERR_INVTYPE=1005;

    constructor(address registry, bytes2[] memory juris, uint8[] memory invTypes) {
        reg = IIdentityRegistry2(registry);
        for (uint i=0;i<juris.length;i++) allowedJuris[juris[i]] = true;
        for (uint i=0;i<invTypes.length;i++) allowedInvestorType[invTypes[i]] = true;
    }

    // BUG: checks sender KYC but NOT receiver KYC
    function canTransfer(address from, address to, uint256, bytes calldata)
        external view returns (bool ok, uint256 reason)
    {
        if (from != address(0)) {
            if (!reg.isVerified(from)) return (false, ERR_SND_KYC);
            if (disallowBlacklisted && reg.isBlacklisted(from)) return (false, ERR_BLACK);
            if (!allowedJuris[reg.jurisdictionOf(from)]) return (false, ERR_JURIS);
            if (!allowedInvestorType[reg.investorTypeOf(from)]) return (false, ERR_INVTYPE);
        }
        // ❌ no receiver KYC check here
        return (true, OK);
    }
}