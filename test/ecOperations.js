const rp = require('request-promise-native')
const EcOperations = artifacts.require('EcOperations');
let instance;

contract('EcOperations', (accounts) => {
  beforeEach(async () => {
    instance = await EcOperations.new({from: accounts[0]});
  });

  //it('ecadd: should return correct result', async () => {
  //  ax = "1"
  //  ay = "2"
  //  bx = "1"
  //  by = "2"
  //  value = await instance.ecAdd.call(ax, ay, bx, by);
  //  assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
  //  assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  //});

  //it('ecmul: should return correct result', async () => {
  //  ax = "1"
  //  ay = "2"
  //  b = "0x03"
  //  value = await instance.ecMul.call(ax, ay, b);
  //  console.log(value[0].toString(16))
  //  console.log(value[1].toString(16))
  //  assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
  //  assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  //});

  it('ecAddc: should return correct result', async () => {
    //ax = "1"
    //ay = "2"
    //az = "1"
    //bx = "1"
    //by = "2"
    //bz = "1"
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    //bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    //by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    //bz = "1"
    bx = "0x769bf9ac56bea3ff40232bcb1b6bd159315d84715b8e679f2d355961915abf0"
    by = "0x2ab799bee0489429554fdb7c8d086475319e63b40b9c5b57cdf1ff3dd9fe2261"
    bz = "1"
    value = await instance.ecAddc(ax, ay, az, bx, by, bz);
    console.log(value)
    console.log(value[0].toString(16))
    console.log(value[1].toString(16))
    console.log(value[2].toString(16))
    //assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    //assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  });
});
