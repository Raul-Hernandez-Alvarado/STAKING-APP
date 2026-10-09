# 🥩 Staking App - Smart Contracts

This repository contains the smart contracts for a decentralized Staking application. The project is built and optimized using the **Foundry** framework and leverages **OpenZeppelin Contracts** for security and standardization.

## 🛠 Tech Stack

*   **Solidity**
*   **Foundry** (Forge, Cast, Anvil) for compilation, testing, and deployment.
*   **OpenZeppelin Contracts** for secure and standardized implementations (ERC20, ERC4626, ReentrancyGuard, etc.).
*   **GitHub Actions** for Continuous Integration (CI) and automated testing.

## 📦 Prerequisitese

You will need to have [Foundry](https://getfoundry.sh/) installed on your local machine.

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## 🚀 Installation & Setup

1. Clone the repository and navigate into the project directory:
   ```bash
   git clone <YOUR_REPOSITORY_URL>
   cd STAKING-APP
   ```

2. Install the project dependencies (`forge-std` and `openzeppelin-contracts`):
   ```bash
   forge install
   ```

3. Compile the smart contracts:
   ```bash
   forge build
   ```

## 🧪 Testing & Security

The project uses the Foundry testing environment to ensure the robustness of the contracts.

To run the complete test suite:
```bash
forge test
```

To view detailed traces in the terminal during debugging (ideal for auditing internal calls and failures):
```bash
forge test -vvvv
```

## ⛽ Gas Optimization

To generate a gas consumption report for the contracts and evaluate optimizations (such as efficient loop usage, `unchecked` blocks, or storage variables):
```bash
forge snapshot
```
This will generate (or update) the `.gas-snapshot` file, which is highly useful for keeping strict track of function consumption.

## 📂 Project Structure

*   `src/`: Main source code of the smart contracts.
*   `test/`: Test scripts written in Solidity using `forge-std`.
*   `script/`: Deployment scripts and on-chain interactions.
*   `lib/`: External dependencies managed by git submodules (`forge-std` and `openzeppelin-contracts`).
*   `.github/workflows/`: CI/CD pipelines (contains `test.yml` to run tests automatically on every push/PR).

## 📄 License

