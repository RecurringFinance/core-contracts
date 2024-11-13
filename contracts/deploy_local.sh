# Check if Anvil is running
if ! nc -z localhost 8545 >/dev/null 2>&1; then
    echo "Error: Anvil is not running on localhost:8545"
    echo "Please start Anvil before running this script"
    exit 1
fi

echo "Anvil is running on localhost:8545"

# Build Contracts
forge build --via-ir

# Test Contracts
forge test --via-ir

# Deploy Contracts
echo "\n\nDeploying Contracts"
forge script scripts/deploy_local.s.sol --rpc-url=http://localhost:8545 --broadcast

# Copy ABI to webApp
cp ./out/DistributorFactory.sol/DistributorFactory.json ../webApp/src/lib/DistributorFactoryAbi.json
cp ./out/Distributor.sol/Distributor.json ../webApp/src/lib/DistributorAbi.json

# Copy ABI to functions
cp ./out/DistributorFactory.sol/DistributorFactory.json ../functions/src/abis/DistributorFactory.json
cp ./out/Distributor.sol/Distributor.json ../functions/src/abis/Distributor.json
