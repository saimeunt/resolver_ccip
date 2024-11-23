# Resolver CCIP

## Description

Resolver CCIP is a smart contract implementation in Cairo for Starknet that enables CCIP-Read (Cross-Chain Interoperability Protocol Read) functionality. This resolver allows for efficient off-chain data resolution while maintaining the security guarantees of the blockchain.

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

## Usage

1. Configure your environment:
```bash
cp .env.example .env
# Edit .env with your configuration
```

2. Deploy the resolver:
To deploy the contracts:
```bash
python scripts/deploy.py
```


## Testing

Run Cairo tests:
```bash
scarb test
```

For Python tests:
```bash
pytest
```

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
