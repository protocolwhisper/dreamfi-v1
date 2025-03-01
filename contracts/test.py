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
    oracle = aggregator_deployer.deploy(name, decimals, price)
    token = erc20_deployer.deploy(name, name, decimals, "Custom Token", "1")
    print("Deployed " + name + " token at " + token.address)
    return oracle, token

btcOracle, btcToken = create_asset("BTC", 1000, 3, 10_000)
ethOracle, ethToken = create_asset("ETH", 105435, 2, 100_000_000)

pool_addr, cdp_addr = b['factory'].new_pool(
    [
        (btcOracle.address, btcToken.address),
        (ethOracle.address, ethToken.address),
    ],
    "Pool 1",
    "P1",
)

pool_abi = boa.load_vyi('IPool.vyi').at(pool_addr)
cdp_abi = boa.load_vyi('IERC20.vyi').at(cdp_addr)

# some random thing
user_pk = '0x4858682030405060708048586820304050607080'

print('pool_addr', pool_addr, 'cdp_addr', cdp_addr)

btcToken.mint(boa.env.eoa, 100)
pool_abi.deposit(btcToken.address, 10)