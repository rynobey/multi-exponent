pragma solidity ^0.4.23;

contract EcOperations {
  function ecAdd(uint256 ax, uint256 ay, uint256 bx, uint256 by) public view returns(uint256[2] p) {
    uint256[4] memory input;
    input[0] = ax;
    input[1] = ay;
    input[2] = bx;
    input[3] = by;
    assembly {
      if iszero(staticcall(sub(gas, 2000), 0x06, input, 0x80, p, 0x40)) {
        revert(0, 0)
      }
    }
  }

  function ecMul(uint256 x, uint256 y, uint256 scalar) public view returns(uint256[2] p) {
    uint256[3] memory input;
    input[0] = x;
    input[1] = y;
    input[2] = scalar;
    assembly {
      // call ecmul precompile
      if iszero(staticcall(sub(gas, 2000), 0x07, input, 0x60, p, 0x40)) {
        revert(0, 0)
      }
    }
  }

 /* This function uses a set of precomputed sums of group elements in order
  * to significantly speed-up the calculation of an EC multi-scalar multiplication.
  * This speed-up will only be available where the multiplications are performed
  * using a set of precomputed values specially created for the given bitSetSize,
  * computeSetSize and set of group elements. If the provided precomputations
  * are missing the values required by the calculation, they will be
  * calculated and persisted for future use. If no precomputed values are
  * passed in, the necessary values will be calculated, but not persisted.
  */
  function ecMultiMul(uint256[] x, uint256[] y, uint256[] scalar, uint numComputeSetBits) public view returns(uint256[2] p) {
    uint numBitSetBits = 256; // TODO: cater for other bit set sizes and move to input parameter
    // TODO: cater for precomputed values to be provided as input parameter (by reference)
    // TODO: check that 256 is divisible by numBitSetBits with remainder = 0
    // TODO: check that numBitSetBits <= 256
    // check that all input arrays have the same length
    require(x.length == y.length);
    require(y.length == scalar.length);
    // check that (256 / numBitSetBits) * scalar.length is divisible by the numComputeSetBits with remainder = 0
    require(256/numBitSetBits*scalar.length % numComputeSetBits == 0);
    uint numComputeSets = 256/numBitSetBits*scalar.length/numComputeSetBits;
    uint256 numComputeSums = 2**numComputeSetBits - 1;
    // allocate memory for precomputations (2*uint256 for each group element)
    uint256[] memory data = new uint256[](2*numComputeSums*numComputeSets);
    // set output group element to zero
    uint256[2] memory output;
    // loop over inputs and extract bits from scalars
    for (uint i = 0; i < numBitSetBits; i++) {
      // if no precomputations are provided
      // extract bits of current bit set
      uint256[] memory bitMasks = calcBitMasks(i, numBitSetBits);
      for (uint j = 0; j < numComputeSets; j++) {
        // compute decimal number (to be used as array index)
        uint idx = calcIndex(scalar, bitMasks, j, numComputeSetBits, numBitSetBits, i);
        //data[i*numComputeSets*2 + idx*2] = x[j*numComputeSetBits];
        //data[i*numComputeSets*2 + idx*2 + 1] = y[0];
        //output[0] = 2*output[0] + x[0];
        //output[1] = 2*output[1] + y[0];
      }
    }
    // loop over sets
      // loop over numbers/bit-strings in set
        // compute corresponding sum of group elements, skip if exists
    // loop over bitSet positions, starting from MSB
      // loop over sets
        // add precomputed sum of group elements
      // double current answer
    // return final sum
    p = output;
    return p;
  }

  function calcIndex(uint256[] scalar, uint256[] bitMasks, uint computeSetPosition, uint numComputeSetBits, uint numBitSetBits, uint bitPosition) public view returns(uint idx) {
    for (uint i = 0; i < numComputeSetBits; i++) {
      uint scalarIdx = computeSetPosition*numComputeSetBits + i/(256/numBitSetBits);
      uint maskIdx = i%(256/numBitSetBits);
      uint numShiftPositions = bitPosition-(i%(256/numBitSetBits))*numBitSetBits;
      uint digit = (scalar[scalarIdx] & bitMasks[maskIdx])/(2**numShiftPositions);
      if (digit == 1) {
        idx = idx + (2**i);
      }
    }
    return idx;
  }

  function calcBitMasks(uint bitPosition, uint numBitSetBits) public view returns(uint256[] bitMasks) {
    //uint256[] memory bitMasks = new uint[](256/numBitSetBits);
    for (uint i = 0; i < (256/numBitSetBits); i++) {
      bitMasks[i] = uint256(2**(256-i*numBitSetBits-bitPosition-1));
    }
    return bitMasks;
  }
}
