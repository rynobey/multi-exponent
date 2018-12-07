const KeystoreProvider = require("keystore-provider")
const URL = require('url').URL
const config = require("./config")
const blockchainNodeAddress = new URL(config.blockchainNodeAddress)
const keystoreProvider = new KeystoreProvider(
  config.keystoreAddress,
  config.blockchainNodeAddress
)

module.exports = {
  networks: {
    from_env: {
      host: blockchainNodeAddress.host,
      port: blockchainNodeAddress.port,
      network_id: config.blockchainNodeNetId,
      gasPrice: config.blockchainNodeGasPrice
    },
    keystore_provider: {
      provider: keystoreProvider,
      network_id: config.blockchainNodeNetId,
      gasPrice: config.blockchainNodeGasPrice
    }
  }
}
