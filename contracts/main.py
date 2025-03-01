import boa
from eth_account import Account
import os
from dotenv import load_dotenv
import argparse
import subprocess

# Load environment variables
load_dotenv()
PRIVATE_KEY = os.getenv('PRIVATE_KEY')

def setup_environment(is_local: bool = True):
    network = 'https://sepolia.base.org'
    
    # Create account from private key
    account = Account.from_key(PRIVATE_KEY)
    print(f"Using account: {account.address}")
    
    if is_local:
        print("Using local fork...")
        boa.env.fork(network)
        boa.env.eoa = account.address
        # Fund the account in the fork
        boa.env.set_balance(account.address, 10**20)
    else:
        print(f"Connecting to {network}...")
        boa.set_network_env(network)
        boa.env.eoa = account.address
        
        # Add the account object (not just the private key)
        boa.env.add_account(account)
    
    return account

def deploy_contracts(is_local: bool = True):
    """Deploy contracts without verification"""
    account = setup_environment(is_local)
    
    try:
        # Deploy blueprints
        print("Deploying pool blueprint...")
        pool_blueprint = boa.load_partial("pool.vy")
        pool_blueprint_contract = pool_blueprint.deploy_as_blueprint()
        print(f"Pool blueprint deployed at: {pool_blueprint_contract.address}")
        
        # For token, use standard deployment and avoid blueprint
        print("Deploying token contract...")
        name = "CDP Token"
        symbol = "CDP"
        decimals = 18
        name_eip712 = "Dream Finance" 
        version_eip712 = "1"
        
        # In Titanoboa, we pass constructor args directly to boa.load()
        token_contract = boa.load("erc20.vy", 
            name, symbol, decimals, name_eip712, version_eip712)
        print(f"Token contract deployed at: {token_contract.address}")
        
        # Factory deployment follows the same pattern
        print("Deploying factory...")
        factory = boa.load("factory.vy", 
            account.address,
            pool_blueprint_contract.address, 
            token_contract.address
        )
        print(f"Factory deployed at: {factory.address}")
        
        return {
            "pool_blueprint": pool_blueprint_contract,
            "token": token_contract,
            "factory": factory
        }
    
    except Exception as e:
        print(f"Deployment failed: {e}")
        return None

