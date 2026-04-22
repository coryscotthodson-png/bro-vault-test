// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TraceLogger {
    event Step(string from, string to, string action);

    function _log(
        string memory from,
        string memory to,
        string memory action
    ) internal {
        emit Step(from, to, action);
    }
}
