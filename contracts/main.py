import boa
boa.set_network_env('https://rpc.ankr.com/eth_sepolia')

#c = boa.load(
 #   "oracle.vy",)
##
import boa
s = boa.load_partial("pool.vy")
blueprint = s.deploy_as_blueprint()
deployer = boa.load("factory.vy", blueprint)
token = s.at(deployer.create_new_pool([0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22], "BTC50/ETH50", "B5E")) #FAKE ASSET
get_address = token.get_address()

#x = c.getTokenPrice('0x5fb

print(get_address) 

