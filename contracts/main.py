import boa
boa.set_network_env('https://rpc.ankr.com/eth_sepolia')

c = boa.load(
    "oracle.vy",)


x = c.getTokenPrice('0x5fb1616F78dA7aFC9FF79e0371741a747D2a7F22')

print(x)

