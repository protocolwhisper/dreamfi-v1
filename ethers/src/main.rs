use ethers::{
    core::types::Address,
    middleware::SignerMiddleware,
    providers::{Http, Provider},
    signers::{LocalWallet, Signer},
    contract::abigen,
    middleware::Middleware,
};
use eyre::Result;
use std::{env, sync::Arc, str::FromStr};
use dotenv::dotenv;

#[tokio::main]
async fn main() -> Result<()> {
    // Load environment variables from .env file
    dotenv().ok();
    abigen!(Factory, "../contracts/factory_abi.json");
    
    // Get environment variables
    let private_key = env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set");
    let rpc_url = "https://sepolia.base.org";
    let factory_address = env::var("FACTORY_ADDRESS").expect("FACTORY_ADDRESS must be set");
    
    println!("Connecting to {}", rpc_url);
    
    // Set up provider and wallet
    let provider = Provider::<Http>::try_from(rpc_url)?;
    let chain_id = provider.get_chainid().await?;
    let wallet = private_key.parse::<LocalWallet>()?.with_chain_id(chain_id.as_u64());
    
    let client = Arc::new(SignerMiddleware::new(provider, wallet.clone()));
    
    // Connect to the factory contract
    let factory_address = Address::from_str(&factory_address)?;
    let factory = Factory::new(factory_address, client.clone());
    
    // Example: Calling view functions
    let admin_address = factory.admin().call().await?;
    println!("Factory Admin: {}", admin_address);
    
    Ok(())
} 