// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    /*///////////////////////////////////////////////
    ////////////////  ERRORS ////////////////////////
    ///////////////////////////////////////////////*/

    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    /*///////////////////////////////////////////////
    ////////////////  STATE VARIABLES ///////////////
    ///////////////////////////////////////////////*/

    IEntryPoint private immutable i_entryPoint;
    // Nonce uniqueness is managed by the EntryPoint itself, so we shouldn't do anything
    // uint256 nonce;

    /*///////////////////////////////////////////////
    ////////////////  MODIFIERS //////////////////////
    ///////////////////////////////////////////////*/

    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    // This contract needs to accept funds in order to pay for transactions
    receive() external payable {}

    /*///////////////////////////////////////////////
    ////////////////  EXTERNAL FUNCTIONS ////////////
    ///////////////////////////////////////////////*/

    function execute(address destination, uint256 value, bytes calldata functionData)
        external
        requireFromEntryPointOrOwner
    {
        (bool success, bytes memory result) = destination.call{value: value}(functionData);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    // A signature is valid if it's the contract owner
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        // _validateNonce();
        // This is what will pay for the gas, here we could specify a paymaster maybe?
        _payPrefund(missingAccountFunds);
    }

    /*///////////////////////////////////////////////
    ////////////////  INTERNAL FUNCTIONS ////////////
    ///////////////////////////////////////////////*/

    // EIP-191 version of the signed hash
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            // Maybe this this is not needed but the compiler likes it vvv
            require(success, "MinimalAccount: PayPrefund failed");
        }
    }

    /*///////////////////////////////////////////////
    ////////////////  GETTERS ///////////////////////
    ///////////////////////////////////////////////*/
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
