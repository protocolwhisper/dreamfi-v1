import os
import boa
from main import deploy_contracts

is_local = True
os.environ['PRIVATE_KEY'] = '0x3252435354259943959345943599768adbfedbfed90213448384234890294958'
b = deploy_contracts(is_local)

print('deploying aggregator blueprint')
aggregator_deployer = boa.load_partial('aggregator.vy')
erc20_deployer = boa.load_partial('erc20.vy')

def create_asset(name, price, decimals, supply):
    print("Deploying " + name + " token")
    oracle = aggregator_deployer.deploy(name, decimals, price)
    token = erc20_deployer.deploy(name, name, decimals, "Custom Token", "1")
    return oracle, token

btcOracle, btcToken = create_asset("BTC", 1000, 3, 10_000)

user_pk = '0x3252435354259943959345943599768adbfedbfed90213448384234890290008'

pool_addr, cdp_addr = b['factory'].new_pool(
    [btcToken.address],
    "Pool 1",
    "P1",
)
