// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

/**
 * @dev Proxy contract supporting upgradeability, based on a simplified version of EIP-1822
 */
contract Proxy {
    address public owner;

    /**
     * @dev Emit when the logic contract is updated
     */
    event ImplementationUpdated(address indexed target);

    /**
     * @notice Save the implementation address
     * @param target The initial implementation address of the logic contract
     * @dev Implementation position in storage is
     * keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
     */
    constructor(address target) {
        owner = msg.sender;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, target)
        }

        emit ImplementationUpdated(target);
    }

    /**
     * @notice Upgrade the logic contract to one on the new implementation address
     * @dev Implementation position in storage is
     * keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
     * @param target New address of the upgraded logic contract
     */
    function updateImplementation(address target) external {
        require(msg.sender == owner, "Proxy: caller is not the owner");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, target)
        }

        emit ImplementationUpdated(target);
    }

    /**
     * @notice get the implementation address of the current logic contract
     * @dev Implementation position in storage is
     * keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
     * @return implementation Logic contract address
     */
    function getImplementation() external view returns (address implementation) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            implementation := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
        }
    }

    /**
     * @dev Fallback function that delegates calls to the logic contract. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _delegate();
    }

    /**
     * @dev Fallback function that delegates calls to the logic contract. Will run if call data
     * is empty.
     */
    receive() external payable {
        _delegate();
    }

    /**
     * @notice Delegate all function calls to the logic contract
     */
    function _delegate() internal {
        assembly {
            let implementation := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
