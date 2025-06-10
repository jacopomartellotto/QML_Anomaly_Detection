import json
from web3 import Web3

# === 1. Connection to Ganache ===
ganache_url = "http://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))

if not web3.is_connected():
    raise ConnectionError("❌ Non connesso a Ganache. Verifica che sia in esecuzione su http://127.0.0.1:7545")

# === 2. Use first account on Ganache ===
account = web3.eth.accounts[0]
web3.eth.default_account = account

# === 3. Load ABI and Bytecode from builded JSON ===
with open("Blockchain/NewSecureAggregation.json", "r") as f:
    contract_json = json.load(f)
    abi = contract_json["abi"]
    bytecode = contract_json["bytecode"]

# === 4. Prepare and deploy contract ===
SecureAggregation = web3.eth.contract(abi=abi, bytecode=bytecode)
print("🚀 Deploying contract...")

tx_hash = SecureAggregation.constructor().transact()
tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)

# === 5. Show contract address ===
contract_address = tx_receipt.contractAddress
print(f"✅ Contratto deployato con successo!")
print(f"📍 Contract Address: {contract_address}")
