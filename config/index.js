const fs = require('fs')
const path = require('path')
const configPath = process.env.CONFIG_PATH || './config/config.json'
const configFile = fs.readFileSync(path.resolve(configPath), 'utf8')
const config = JSON.parse(configFile)

module.exports = {
  apiServerAddress: process.env.API_SERVER_ADDRESS || config.apiServerAddress,
  decimalPrecision: process.env.DECIMAL_PRECISION || config.decimalPrecision,
  blockchainProxyAddress: process.env.BLOCKCHAIN_PROXY_ADDRESS || config.blockchainProxyAddress,
  keystoreAddress: process.env.KEYSTORE_ADDRESS || config.keystoreAddress,
  blockchainNodeAddress: process.env.BLOCKCHAIN_NODE_ADDRESS || config.blockchainNodeAddress,
  blockchainNodeNetId: process.env.BLOCKCHAIN_NODE_NET_ID || config.blockchainNodeNetId,
  blockchainNodeGasPrice: process.env.BLOCKCHAIN_NODE_GAS_PRICE || config.blockchainNodeGasPrice
}

console.log("\nDEFAULTS LOADED:", path.resolve(configPath))
console.log()
console.log("RUNNING WITH CONFIGURATION:\n")
console.log(module.exports)
console.log()
