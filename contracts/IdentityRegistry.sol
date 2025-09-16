// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.2/contracts/access/AccessControl.sol";

/**
 * Minimal Identity Registry (demo). Stores flags/attributes only (no PII).
 * Roles:
 *  - DEFAULT_ADMIN_ROLE
 *  - KYC_ADMIN_ROLE: can set KYC + attributes
 *  - SANCTIONS_ADMIN_ROLE: can set blacklist
 */
contract IdentityRegistry is AccessControl {
    bytes32 public constant KYC_ADMIN_ROLE = keccak256("KYC_ADMIN_ROLE");
    bytes32 public constant SANCTIONS_ADMIN_ROLE = keccak256("SANCTIONS_ADMIN_ROLE");

    mapping(address => bool) public isVerified;          // KYC flag
    mapping(address => bool) public isBlacklisted;       // sanctions flag
    mapping(address => bytes2) public jurisdictionOf;    // e.g., "HK" = 0x484b, "SG" = 0x5347
    mapping(address => uint8)  public investorTypeOf;    // 1=RETAIL, 2=PROFESSIONAL, 3=INSTITUTIONAL

    event KycUpdated(address indexed user, bool ok);
    event BlacklistUpdated(address indexed user, bool ok);
    event AttributesUpdated(address indexed user, bytes2 juris, uint8 invType);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KYC_ADMIN_ROLE, admin);
        _grantRole(SANCTIONS_ADMIN_ROLE, admin);
    }

    function setKyc(address user, bool ok) external onlyRole(KYC_ADMIN_ROLE) {
        isVerified[user] = ok;
        emit KycUpdated(user, ok);
    }

    function setBlacklist(address user, bool ok) external onlyRole(SANCTIONS_ADMIN_ROLE) {
        isBlacklisted[user] = ok;
        emit BlacklistUpdated(user, ok);
    }

    function setAttributes(address user, bytes2 juris, uint8 invType)
        external onlyRole(KYC_ADMIN_ROLE)
    {
        jurisdictionOf[user] = juris;
        investorTypeOf[user] = invType;
        emit AttributesUpdated(user, juris, invType);
    }
}