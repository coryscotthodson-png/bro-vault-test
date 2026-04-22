// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AuditReport {
    enum Severity { LOW, MEDIUM, HIGH, CRITICAL }

    struct Finding {
        string title;
        string description;
        uint256 vulnValue;
        uint256 fixedValue;
        Severity severity;
        string proof;
    }

    Finding[] public findings;

    function addFinding(
        string memory title,
        string memory description,
        uint256 vulnValue,
        uint256 fixedValue,
        Severity severity,
        string memory proof
    ) public {
        findings.push(Finding(
            title,
            description,
            vulnValue,
            fixedValue,
            severity,
            proof
        ));
    }

    function count() external view returns (uint256) {
        return findings.length;
    }
}
