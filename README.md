# Audit Reputation System Smart Contract
This project is a Clarity smart contract that manages an audit reputation system. It includes
functionality for handling auditors, reputation tokens, role-based access control, and audits. The
contract allows for minting, burning, and transferring of reputation tokens, as well as managing a list
of auditors.
## Features
- **Fungible Token (`reputation-token`)**: Implements a reputation token with a fixed supply.
- **Auditor Management**: Allows for verifying, auditing, and removing auditors.
- **Role-Based Access Control**: Supports role management with a whitelist system for specific
users.
- **Safe Token Transfers**: Supports token transfer between users, with validation checks for
sufficient balances, zero amounts, and self-transfers.
- **Max Supply Enforcement**: Ensures that the total supply of reputation tokens does not exceed
the defined maximum.
- **Burning Tokens**: Allows users to burn their tokens, reducing the total supply.
## Contract Structure
### Constants
- **contract-owner**: Owner of the contract, who has special permissions (like verifying auditors).
- **max-auditors**: Maximum number of auditors that can be verified.
- **max-token-supply**: Maximum total supply of reputation tokens.
- Various error codes for handling validation failures.
### Data Maps and Variables
- **auditors**: A map of principals (addresses) representing auditors.
- **whitelist**: A map of principals that are whitelisted for specific roles.
- **roles**: A map of principals and their respective roles.
- **token-name**, **token-symbol**, **token-decimals**, **token-uri**: Metadata related to the
reputation token.
- **auditor-count**: A variable that tracks the number of verified auditors.
### Public Functions
- **transfer**: Transfers reputation tokens between users with validation checks.
- **verify-auditor**: Verifies a new auditor, ensuring the maximum number of auditors is not
exceeded.
- **burn**: Allows a user to burn (destroy) some of their tokens.
- **remove-auditor**: Removes an auditor from the system.
- **audit-auditor**: Audits an existing auditor.
- **get-balance**: Retrieves the token balance of a specific user.
- **get-total-supply**: Returns the total supply of reputation tokens.
- **get-auditor-count**: Returns the current number of verified auditors.
- **get-contract-owner**: Returns the contract owner's address.
- **check-max-supply**: Verifies if the maximum token supply has been exceeded.
### Read-Only Functions
- **is-whitelisted**: Checks if a user is in the whitelist.
- **is-auditor**: Checks if a specific address is a verified auditor.
- **get-name**, **get-symbol**, **get-decimals**: Retrieves metadata about the reputation token.
- **get-token-uri**: Retrieves the token's metadata URI.
- **get-role**: Returns the role of a specific user.
### Safe Math Functions
- **safe-add**: Adds two unsigned integers, ensuring no overflow.
- **safe-subtract**: Subtracts two unsigned integers, ensuring no underflow.
## Requirements
- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing.
- Stacks Blockchain for deployment (Testnet/Mainnet).
## Setup
1. **Clone the repository**:
 ```bash
 git clone <repository-url>
 ```
2. **Install Clarinet**:
 If you don't have Clarinet installed, follow the [official
instructions](https://github.com/hirosystems/clarinet#installing) to set it up.
3. **Run tests**:
 To test the contract locally using Clarinet:
 ```bash
 clarinet test
 ```
## Deployment
1. **Deploy to the Stacks Blockchain** (Testnet/Mainnet):
 Use the Stacks CLI to deploy your contract. For example:
 ```bash
 stx deploy-contract audit-reputation ./contracts/audit-reputation.clar --testnet
 ```
2. After deployment, use the contract's address and reference it in other smart contracts if
necessary.
## Example Usage
- **Transfer Tokens**:
 Call the `transfer` function to send reputation tokens between users.
 ```clarity
 (contract-call? .audit-reputation transfer u100 tx-sender recipient)
 ```
- **Verify Auditor**:
 Call the `verify-auditor` function to add a new auditor.
 ```clarity
 (contract-call? .audit-reputation verify-auditor auditor-address)
 ```

