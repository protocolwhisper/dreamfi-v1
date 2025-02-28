import boa
from eth_account import Account
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Setup network
boa.set_network_env('https://rpc.ankr.com/eth_sepolia')

# Get private keys and API key from environment variables
PRIVATE_KEY = os.getenv('PRIVATE_KEY')
ETHERSCAN_API_KEY = os.getenv('ETHERSCAN_API_KEY')

def deploy_and_verify():
    # Create account from private key
    account = Account.from_key(PRIVATE_KEY)
    
    # Deploy blueprints
    pool_blueprint = boa.load_partial("pool.vy")
    token_blueprint = boa.load_partial("token.vy")  # Your CDP token contract
    
    pool_blueprint_contract = pool_blueprint.deploy_as_blueprint()
    token_blueprint_contract = token_blueprint.deploy_as_blueprint()
    
    # Deploy factory
    factory = boa.load("factory.vy", 
        account.address,  # admin
        pool_blueprint_contract.address, 
        token_blueprint_contract.address
    )
    
    # Verify contracts on Etherscan
    try:
        boa.verify_source(
            pool_blueprint_contract.address,
            "pool.vy",
            ETHERSCAN_API_KEY
        )
        
        boa.verify_source(
            token_blueprint_contract.address,
            "token.vy",
            ETHERSCAN_API_KEY
        )
        
        boa.verify_source(
            factory.address,
            "factory.vy",
            ETHERSCAN_API_KEY,
            constructor_args=[
                account.address,
                pool_blueprint_contract.address,
                token_blueprint_contract.address
            ]
        )
        
        print("Contracts verified successfully!")
        
    except Exception as e:
        print(f"Verification failed: {e}")
    
    return factory

if __name__ == "__main__":
    factory = deploy_and_verify()
    print(f"Factory deployed at: {factory.address}") 

