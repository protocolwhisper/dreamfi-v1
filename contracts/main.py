import boa
from eth_account import Account
import os
from dotenv import load_dotenv
import argparse

# Load environment variables
load_dotenv()
PRIVATE_KEY = os.getenv('PRIVATE_KEY')
ETHERSCAN_API_KEY = os.getenv('ETHERSCAN_API_KEY')

def setup_environment(is_local: bool = True):
    network = 'https://base-sepolia.gateway.tenderly.co'
    if is_local:
        boa.env.fork(network)
    else:
        boa.set_network_env(network)
    
    account = Account.from_key(PRIVATE_KEY)
    boa.env.eoa = account.address
    return account

def deploy_and_verify(is_local: bool = True):
    account = setup_environment(is_local)
    
    # Deploy blueprints
    pool_blueprint = boa.load_partial("pool.vy")
    token_blueprint = boa.load_partial("erc20.vy")
    
    pool_blueprint_contract = pool_blueprint.deploy_as_blueprint()
    token_blueprint_contract = token_blueprint.deploy_as_blueprint()
    
    # Deploy factory
    factory = boa.load("factory.vy", 
        account.address,
        pool_blueprint_contract.address, 
        token_blueprint_contract.address
    )
    
    if not is_local:
        try:
            # Verify only on real network
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
    parser = argparse.ArgumentParser()
    parser.add_argument('--local', action='store_true', help='Deploy to local fork')
    args = parser.parse_args()
    
    factory = deploy_and_verify(is_local=args.local)
    print(f"Factory deployed at: {factory.address}") 

