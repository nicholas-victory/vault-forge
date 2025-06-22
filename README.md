# VaultForge Protocol

> **Vault your Bitcoin, Forge your Future**

A revolutionary Bitcoin-native overcollateralized lending protocol built on Stacks Layer 2, enabling Bitcoin holders to access liquidity while maintaining exposure to BTC appreciation.

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-purple)](https://stacks.co)
[![Bitcoin](https://img.shields.io/badge/Secured%20by-Bitcoin-orange)](https://bitcoin.org)

## 🚀 Overview

VaultForge pioneers a new paradigm in DeFi by creating the first truly Bitcoin-centric overcollateralized lending marketplace. Users can vault their Bitcoin as collateral to forge STX loans without selling their appreciating BTC holdings. Every transaction benefits from Bitcoin's unmatched security while enabling instant settlements and programmable money features.

### Key Features

- **🔐 Bitcoin-First Architecture**: Direct Bitcoin collateralization without wrapping
- **⛓️ Proof-of-Transfer Security**: Inherits Bitcoin's security model via Stacks PoX
- **📊 Dynamic Risk Engine**: Real-time collateral ratio monitoring and liquidation
- **🔒 Zero-Custody Design**: Users maintain self-custody throughout the lending cycle
- **💰 Yield-Optimized**: Competitive interest rates with transparent fee structures

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Bitcoin L1    │    │   Stacks Layer   │    │  VaultForge     │
│                 │◄──►│      (PoX)       │◄──►│   Protocol      │
│  • Settlement   │    │  • Smart Contracts│    │  • Lending      │
│  • Security     │    │  • Clarity VM     │    │  • Liquidation  │
│  • Finality     │    │  • Block Production│    │  • Oracle Feeds │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Contract Architecture

The VaultForge Protocol consists of a single, comprehensive smart contract with the following core components:

#### Data Layer

- **Loan Registry**: Primary storage for all loan positions
- **User Portfolio**: Tracking of active loans per user
- **Oracle Feeds**: Real-time price data for collateral assets
- **Risk Parameters**: Dynamic configuration for collateral ratios and liquidation thresholds

#### Business Logic Layer

- **Collateral Management**: Deposit, withdrawal, and validation functions
- **Loan Origination**: Creation and validation of new lending positions
- **Interest Calculation**: Time-based accrual using block height
- **Liquidation Engine**: Automated risk assessment and position closure

#### Access Control Layer

- **Admin Functions**: Platform initialization and parameter updates
- **User Functions**: Lending operations and portfolio management
- **Read-Only Interface**: Data queries and analytics

## 📊 Data Flow Diagram

```
┌─────────────┐
│   User      │
│  (Borrower) │
└──────┬──────┘
       │
       │ 1. Deposit Collateral
       ▼
┌─────────────────────┐
│  VaultForge         │
│  Smart Contract     │
├─────────────────────┤
│ • Validate Amount   │
│ • Update Metrics    │
│ • Store Collateral  │
└──────┬──────────────┘
       │
       │ 2. Request Loan
       ▼
┌─────────────────────┐
│  Risk Assessment    │
├─────────────────────┤
│ • Check Ratio       │
│ • Validate Oracle   │
│ • Calculate Terms   │
└──────┬──────────────┘
       │
       │ 3. Create Loan
       ▼
┌─────────────────────┐
│  Loan Registry      │
├─────────────────────┤
│ • Generate Loan ID  │
│ • Store Position    │
│ • Update Portfolio  │
└──────┬──────────────┘
       │
       │ 4. Monitor Health
       ▼
┌─────────────────────┐
│ Liquidation Engine  │
├─────────────────────┤
│ • Price Monitoring  │
│ • Ratio Calculation │
│ • Auto-Liquidation  │
└─────────────────────┘
```

## 🔧 Technical Specifications

### Risk Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Minimum Collateral Ratio | 150% | Required overcollateralization |
| Liquidation Threshold | 120% | Automatic liquidation trigger |
| Interest Rate | 5% | Annual borrowing cost |
| Platform Fee | 1% | Protocol revenue share |

### Supported Assets

- **BTC**: Primary collateral asset
- **STX**: Secondary collateral and loan currency

### Oracle Integration

VaultForge relies on trusted price oracles for:

- Real-time BTC/USD pricing
- Collateral valuation
- Liquidation threshold monitoring

## 🚀 Getting Started

### Prerequisites

- Stacks wallet (Hiro Wallet, Xverse, etc.)
- Bitcoin testnet/mainnet access
- Basic understanding of DeFi lending

### Installation

1. Clone the repository:

```bash
git clone https://github.com/nicholas-victory/vault-forge.git
cd vault-forge
```

2. Install dependencies:

```bash
npm install
```

3. Deploy to Stacks testnet:

```bash
clarinet deploy --network testnet
```

### Basic Usage

#### 1. Initialize Platform (Admin Only)

```clarity
(contract-call? .vaultforge initialize-platform)
```

#### 2. Deposit Collateral

```clarity
(contract-call? .vaultforge deposit-collateral u100000000) ;; 1 BTC in satoshis
```

#### 3. Request Loan

```clarity
(contract-call? .vaultforge request-loan u100000000 u50000000) ;; 1 BTC collateral, 0.5 STX loan
```

#### 4. Repay Loan

```clarity
(contract-call? .vaultforge repay-loan u1 u52500000) ;; Loan ID 1, amount including interest
```

## 🔍 Contract Functions

### Administrative Functions

- `initialize-platform()`: Bootstrap protocol for operations
- `update-collateral-ratio(new-ratio)`: Modify minimum collateral requirements
- `update-liquidation-threshold(new-threshold)`: Adjust liquidation triggers
- `update-price-feed(asset, price)`: Update oracle price data

### Core Lending Functions

- `deposit-collateral(amount)`: Vault Bitcoin as collateral
- `request-loan(collateral, loan-amount)`: Create new lending position
- `repay-loan(loan-id, amount)`: Close loan with interest payment

### Query Functions

- `get-loan-details(loan-id)`: Retrieve comprehensive loan information
- `get-user-loans(user)`: View user's active loan portfolio
- `get-platform-stats()`: Access protocol analytics
- `get-valid-assets()`: List supported collateral types

## 🛡️ Security Features

### Risk Management

- **Overcollateralization**: Minimum 150% collateral ratio
- **Automated Liquidation**: Prevents protocol insolvency
- **Oracle Validation**: Price feed sanity checks
- **Access Controls**: Admin-only sensitive functions

### Smart Contract Security

- **Clarity Language**: Predictable, decidable smart contract execution
- **No Reentrancy**: Built-in protection against common attack vectors
- **Input Validation**: Comprehensive parameter checking
- **Error Handling**: Graceful failure modes with descriptive errors

## 📈 Protocol Economics

### Interest Model

- Fixed 5% annual interest rate
- Interest calculated per block (approximately 144 blocks/day)
- Compound interest accrual

### Fee Structure

- 1% platform fee on loan origination
- No additional fees for repayment or collateral management

### Liquidation Mechanics

- Triggered at 120% collateral ratio
- Immediate position closure
- Collateral retained by protocol for debt coverage

## 🧪 Testing

Run the comprehensive test suite:

```bash
clarinet test
```

### Test Coverage

- Unit tests for all public functions
- Integration tests for lending workflows
- Edge case validation
- Security vulnerability assessments

## 📚 Documentation

- [API Reference](./docs/api.md)
- [Deployment Guide](./docs/deployment.md)
- [Security Audit](./docs/security.md)
- [Economic Model](./docs/economics.md)

## 🤝 Contributing

We welcome contributions to VaultForge Protocol! Please see our [Contributing Guidelines](./CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request
5. Code review and merge

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- **Stacks Foundation** for the revolutionary Proof-of-Transfer consensus
- **Bitcoin Community** for the foundational security layer
- **Clarity Language** developers for predictable smart contracts
- **DeFi Pioneers** who paved the way for decentralized lending
