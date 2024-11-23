# Resolver CCIP

## Overview

Resolver CCIP is a smart contract implementation in Cairo for Starknet that enables CCIP-Read (Cross-Chain Interoperability Protocol Read) functionality. This resolver allows for efficient off-chain data resolution while maintaining the security guarantees of the blockchain.

## Prerequisites

- [Cairo](https://www.cairo-lang.org/docs/quickstart.html) - Smart contract programming language
- [Scarb](https://docs.swmansion.com/scarb/) - Package manager for Cairo
- Python 3.9 or higher
- [Starknet-devnet](https://github.com/0xSpaceShard/starknet-devnet) (for local testing)

## Installation

1. Clone the repository
```bash
git clone https://github.com/lfglabs-dev/resolver_ccip.git
cd resolver_ccip
```

2. Install Python dependencies
```bash
pip install -r requirements.txt
```

3. Build Cairo contracts
```bash
scarb build
```

## Project Structure

```
resolver_ccip/
├── src/                # Cairo smart contracts
│   └── lib.cairo       # Main contract implementation
├── scripts/            # Deployment and utility scripts
├── .env.example        # Environment variables template
├── Scarb.toml         # Cairo project configuration
└── requirements.txt    # Python dependencies
```

## Usage

1. Configure your environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

2. Deploy the resolver:
```bash
python scripts/deploy.py
```

3. Update resolver configuration:
```bash
python scripts/update_resolver.py
```

## Testing

Run Cairo tests:
```bash
scarb test
```

## Development

The project uses:
- Cairo for smart contracts (61.8% of codebase)
- Python for scripts and testing (38.2% of codebase)

## Contributing

1. Fork the repository
2. Create your feature branch
```bash
git checkout -b feature/your-feature-name
```
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Security

For security concerns, please open an issue or contact the maintainers directly.

## Maintainers

- @irisdv
- @Th0rgal
- @Marchand-Nicolas
- @fricoben

For more information or support, please open an issue on the GitHub repository.