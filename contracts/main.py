import boa
from eth_account import Account
import os
from dotenv import load_dotenv
import argparse
import subprocess

# Load environment variables
load_dotenv()

def setup_environment(is_local: bool = True):
    network = 'https://sepolia.base.org'
    
    # Create account from private key
    PRIVATE_KEY = os.getenv('PRIVATE_KEY')
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
        
        # In Titanoboa, we pass constructor args directly to boa.load()
        print("Deploying token blueprint...")
        token_blueprint = boa.load_partial('erc20.vy')
        token_blueprint_contract = token_blueprint.deploy_as_blueprint()
        print(f"Token blueprint deployed at: {token_blueprint_contract.address}")
        
        # Factory deployment follows the same pattern
        print("Deploying factory...")
        factory = boa.load("factory.vy", 
            account.address,
            pool_blueprint_contract.address, 
            token_blueprint_contract.address
        )
        print(f"Factory deployed at: {factory.address}")
        
        return {
            "pool_blueprint": pool_blueprint_contract,
            "token_blueprint": token_blueprint_contract,
            "factory": factory,
            "account": account,
        }
    
    except Exception as e:
        print(f"Deployment failed: {e}")
        return None

deploy_contracts(is_local=False)
