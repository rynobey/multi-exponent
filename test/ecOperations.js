var rp = require('request-promise-native')
const EcOperations = artifacts.require('EcOperations');
let instance;

contract('EcOperations', (accounts) => {
  beforeEach(async () => {
    instance = await EcOperations.new({from: accounts[0]});
  });

  it('ecadd: should return correct result', async () => {
    ax = "1"
    ay = "2"
    bx = "1"
    by = "2"
    value = await instance.ecAdd.call(ax, ay, bx, by);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  });

  it('ecmul: should return correct result', async () => {
    ax = "1"
    ay = "2"
    b = "0x02"
    value = await instance.ecMul.call(ax, ay, b);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  });
});
