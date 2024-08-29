unit module Zeco::Util::SHA256;

constant \h256 = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
constant \k256 = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
                  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
                  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
                  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
                  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
                  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
                  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
                  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2];
constant m32 = uint32.Range.max;
sub _pad (Int() $i) { $i < 16 ?? "0{$i.base(16)}" !! $i.base(16) };
sub _hex (@hs --> Str) {
  @hs.map({  _pad((($_ +> 24) +& 0xFF))
           ~ _pad((($_ +> 16) +& 0xFF))
           ~ _pad((($_ +>  8) +& 0xFF))
           ~ _pad($_ +& 0xFF);
          }).join('');
}
sub _rot(\val, \n) { (val +& m32) +> n +| ((val +& m32) +< (32 - n) +& m32); }
multi sub sha256(Buf[uint32]() $in --> Str) is export {
  my (@ws, $s0, $s1, $ch, $t0, $t1, $maj, @ss);

  $in.append: 0x80;

  my @hs = h256.clone;
  my @bs = (0,4...^($in.elems + ($in.elems%4)))
           .grep(* < $in.elems)
           .map({  (($in[$_  ]//0) +< 24)
                 + (($in[$_+1]//0) +< 16)
                 + (($in[$_+2]//0) +< 8)
                 +  ($in[$_+3]//0) });
  @bs.append(0) while (+@bs * 32) % 15 != 0;
  @bs.append(($in.elems - 1) * 8);

  for (0,16...^+@bs) -> $idx {
    @ws[0..15]  = @bs[$idx..$idx+15].map({$_//0});
    @ss = @hs.clone;
    for 0..63 -> $jdx {
      if $jdx > 15 {
        @ws[$jdx] = (@ws[$jdx-16]
                  + (_rot(@ws[$jdx-15], 7) +^ _rot(@ws[$jdx-15], 18) +^ (@ws[$jdx-15] +> 3))
                  + @ws[$jdx-7] 
                  + (_rot(@ws[$jdx-2], 17) +^ _rot(@ws[$jdx-2], 19) +^ ((@ws[$jdx-2] +> 10)))
                ) +& m32;
      }
      $s1  = _rot(@hs[4], 6) +^ _rot(@hs[4], 11) +^ _rot(@hs[4], 25);
      $ch  = (@hs[4] +& @hs[5]) +| ((+^@hs[4]) +& @hs[6]);
      $t0  = ((@hs[7]//0) + $s1 + $ch + k256[$jdx] + (@ws[$jdx]//0)) +& m32;
      $s0  = _rot(@hs[0], 2) +^ _rot(@hs[0], 13) +^ _rot(@hs[0], 22);
      $maj = @hs[0] +& @hs[1] +^ (@hs[0] +& @hs[2]) +^ (@hs[1] +& @hs[2]);
      $t1  = ($s0 + $maj) +& m32;

      @hs.pop;
      @hs.unshift: ($t0 + $t1) +& m32;
      @hs[4] = (@hs[4] + $t0);
    }
    @hs[$_] += @ss[$_] for 0..7;
  }

  _hex(@hs);
}
multi sub sha256(Str:D $input --> Str) is export { sha256($input.encode); }
