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
  //  value = await instance.ecAddp.call(ax, ay, bx, by);
  //  assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
  //  assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  //});

  //it('ecmul: should return correct result', async () => {
  //  ax = "1"
  //  ay = "2"
  //  b = "0x04"
  //  value = await instance.ecMulp.call(ax, ay, b);
  //  console.log(value[0].toString(16))
  //  console.log(value[1].toString(16))
  ////  assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
  ////  assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
  //});

  it('ecAdd: should return correct result if a is inf', async () => {
    ax = "0"
    ay = "1"
    az = "0"
    bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    bz = "1"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('ecAdd: should return correct result if b is inf', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0"
    by = "1"
    bz = "0"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('ecAdd: should return correct result if a = b', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    bz = "1"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "c696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9");
    assert.strictEqual(value[1].toString(16), "1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6");
    assert.strictEqual(value[2].toString(16), "2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588");
  });

  it('ecAdd: should return correct result if a != b', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0x769bf9ac56bea3ff40232bcb1b6bd159315d84715b8e679f2d355961915abf0"
    by = "0x2ab799bee0489429554fdb7c8d086475319e63b40b9c5b57cdf1ff3dd9fe2261"
    bz = "1"
    value = await instance.ecAdd(ax, ay, az, bx, by, bz);
    assert.strictEqual(value[0].toString(16), "17a863ba135c6a3661e524d687e42ba75d61468e64baf91ef1ecd881f78601d2");
    assert.strictEqual(value[1].toString(16), "1eeff1197f732823f7c6a27a40ad5f08018b088b830651261c776346f201d4ca");
    assert.strictEqual(value[2].toString(16), "2c00d3bf49d8cfec5fd3175537e2b0cddde3a8f3694000bc1d0f3f422cef212a");
  });

  it('ecDbl: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    bx = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    by = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    bz = "1"
    value = await instance.ecDbl(ax, ay, az);
    assert.strictEqual(value[0].toString(16), "c696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9");
    assert.strictEqual(value[1].toString(16), "1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6");
    assert.strictEqual(value[2].toString(16), "2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588");
  });

  it('ecNeg: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.ecNeg(ax, ay, az);
    assert.strictEqual(value[0].toString(16), "30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3");
    assert.strictEqual(value[1].toString(16), "1a76dae6d3272396d0cbe61fced2bc532edac647851e3ac53ce1cc9c7e645a83");
    assert.strictEqual(value[2].toString(16), "1");
  });

  it('isOnCurve: should return correct result', async () => {
    ax = "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3"
    ay = "0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4"
    az = "1"
    value = await instance.isOnCurve(ax, ay, az);
    assert.strictEqual(value, true);
  });

  it('makeAffine: should return correct result', async () => {
    ax = "0xc696a22f504436d53570eb15c5d55d31940e07e4582d78c9380f50e480ca6f9"
    ay = "0x1ad4473c8a4d457dedf6db10348646c18021f8befa70269b6f8545ce11ab30f6"
    az = "0x2bdae7181c14f925cf08bf2d655d3814d14d4893c6a71f8ffe7d7ef4b4314588"
    value = await instance.makeAffine(ax, ay, az);
    assert.strictEqual(value[0].toString(16), "6a7b64af8f414bcbeef455b1da5208c9b592b83ee6599824caa6d2ee9141a76");
    assert.strictEqual(value[1].toString(16), "8e74e438cee31ac104ce59b94e45fe98a97d8f8a6e75664ce88ef5a41e72fbc");
    assert.strictEqual(value[2].toString(16), "1");
  });
});
