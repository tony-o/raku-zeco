unit module Zeco::Util::BST;

use Zeco::Util::Json;

class BST is export {
  has Bool $.root = False;
  has BST $.left is rw = Nil;
  has BST $.right is rw = Nil;
  has $.value is rw = Nil;
  has $.meta is rw = Nil;

  method is-set(--> Bool) { self.defined && Nil !~~ $!value }

  method insert(Str $value, Str $meta) {
    die 'insert can only be called on root nodes' if !$!root;
    if !$.is-set {
      $!value = $value;
      $!meta = $meta;
      return;
    }
    my $par = Nil;
    my $rptr := self;
    while $rptr.defined && $rptr.is-set {
      if $rptr.value gt $value {
        $par = $rptr;
        $rptr := $rptr.left;
      } elsif $rptr.value lt $value {
        $par = $rptr;
        $rptr := $rptr.right;
      } elsif $rptr.value eq $value {
        return;
      }
    }
    if $par.value gt $value {
      $par.left = BST.new(:$value, :$meta);
    } elsif $par.value lt $value {
      $par.right = BST.new(:$value, :$meta);
    }
  }

  method find-partial(Str $v --> List) {
    my ($node, @os);
    my @ss = self;
    while @ss {
      $node = @ss.pop;
      @ss.push($node.left) if $node.left.is-set;
      @ss.push($node.right) if $node.right.is-set;
      @os.push($node.meta) if $node.value.lc.contains($v.lc);
    }

    @os;
  }

  method find(Str $v) {
    return Empty unless self.defined;
    return self if $v eq $!value;
    if $v lt $!value {
      return Empty unless $!left.defined;
      return $!left.find($v);
    } elsif $v gt $!value {
      return Empty unless $!right.defined;
      return $!right.find($v);
    }
    Nil
  }

  method nodes(--> Int) {
    return 0 unless $!root || self.is-set;
    my $count = 0;
    my @nodes = self;
    my $node;
    while @nodes {
      $node = @nodes.pop;
      @nodes.push($node.left) if $node.left.is-set;
      @nodes.push($node.right) if $node.right.is-set;
      $count++;
    }
    $count;
  }

  method serialize(--> Buf) {
    my $nodes = self.nodes;
    my Buf $out .=new;
    my Buf $keys .=new;
    my Buf $metas .=new;

    my @nodes = self;
    my $count = 3;
    my ($node, @offsets, $elems, $lele, $rele);
    while @nodes {
      $node = @nodes.shift;
      if $node.left.is-set {
        @nodes.push($node.left);
        $lele = (@nodes.elems * 8) + $out.elems;
      } else {
        $lele = 0;
      }
      if $node.right.is-set {
        @nodes.push($node.right);
        $rele = (@nodes.elems * 8) + $out.elems;
      } else {
        $rele = 0;
      }

      $out.push(($keys.elems +& 0xFF_00_00_00) +> 24);
      $out.push(($keys.elems +& 0xFF_00_00) +> 16);
      $out.push(($keys.elems +& 0xFF_00) +> 8);
      $out.push(($keys.elems +& 0xFF));
      $out.push(($lele +& 0xFF_00) +> 8);
      $out.push(($lele +& 0xFF));
      $out.push(($rele +& 0xFF_00) +> 8);
      $out.push(($rele +& 0xFF));

      $keys.push(|$node.value.encode, 0x0);
      $keys.push(($metas.elems +& 0xFF_00_00_00) +> 24);
      $keys.push(($metas.elems +& 0xFF_00_00) +> 16);
      $keys.push(($metas.elems +& 0xFF_00) +> 8);
      $keys.push(($metas.elems +& 0xFF));

      $metas.push(|$node.meta.encode, 0x0);
    }

    $elems = $out.elems;
    $out.unshift(($elems +& 0xFF));
    $out.unshift(($elems +& 0xFF_00) +> 8);
    $out.unshift(($elems +& 0xFF_00_00) +> 16);
    $out.unshift(($elems +& 0xFF_00_00_00) +> 24);

    $out.push($keys);
    $elems = $out.elems;
    $out.unshift(($elems +& 0xFF));
    $out.unshift(($elems +& 0xFF_00) +> 8);
    $out.unshift(($elems +& 0xFF_00_00) +> 16);
    $out.unshift(($elems +& 0xFF_00_00_00) +> 24);

    $out.push($metas);

    $out;
  }

  method find-partial-index(IO() $index, Str $v --> List) {
    my Buf $f = $index.slurp(:bin);
    my @ms;
    my $idx = 8;
    my $ptr = 0;
    my $off = 0;
    my $kof = ($f[4] +< 24)
            + ($f[5] +< 16)
            + ($f[6] +< 8)
            + ($f[7])
            + 8;
    my $dof = ($f[0] +< 24) 
            + ($f[1] +< 16)
            + ($f[2] +< 8)
            + ($f[3])
            + 4;
    my ($key, $value);
    while $idx < $kof {
      $off = ($f[$idx  ] +< 24)
           + ($f[$idx+1] +< 16)
           + ($f[$idx+2] +< 8)
           + ($f[$idx+3])
           + $kof;

      $ptr = $off;
      while $f[$ptr] != 0x0 && $ptr < $f.elems {
        $ptr++
      }
      $key = $f.subbuf($off, $ptr - $off).decode;
      if $key.lc.contains($v.lc) {
        $ptr++;
        $off = ($f[$ptr] +< 24)
             + ($f[$ptr+1] +< 16)
             + ($f[$ptr+2] +< 8)
             + ($f[$ptr+3])
             + $dof;

        $ptr = $off+1;
        while $f[$ptr] != 0x0 {
          $ptr++;
        }
        
        @ms.push([$key, $f.subbuf($off, $ptr - $off).decode]);
      }
      $idx += 8;
    }
    @ms;
  }

  method find-index(IO() $index, Str $v --> List) {
    my Buf $f = $index.slurp(:bin);
    my $idx = 8;
    my $ptr = 0;
    my $off = 0;
    my $kof = ($f[4] +< 24)
            + ($f[5] +< 16)
            + ($f[6] +< 8)
            + ($f[7])
            + 8;
    my $dof = ($f[0] +< 24) 
            + ($f[1] +< 16)
            + ($f[2] +< 8)
            + ($f[3])
            + 4;
    my ($key, $value);
    while True {
      $off = ($f[$idx  ] +< 24)
           + ($f[$idx+1] +< 16)
           + ($f[$idx+2] +< 8)
           + ($f[$idx+3])
           + $kof;

      $ptr = $off;
      while $f[$ptr] != 0x0 && $ptr < $f.elems {
        $ptr++
      }
      $key = $f.subbuf($off, $ptr - $off).decode;
      if $key eq $v {
        $ptr++;
        $idx = ($f[$ptr] +< 24)
             + ($f[$ptr+1] +< 16)
             + ($f[$ptr+2] +< 8)
             + ($f[$ptr+3])
             + $dof;

        $ptr = $idx+1;
        while $f[$ptr] != 0x0 {
          $ptr++;
        }
        
        return [$key, $f.subbuf($idx, $ptr - $idx).decode];
      } elsif $v lt $key {
        # Read left
        $ptr = $idx + 4;
        $idx = ($f[$ptr] +< 8)
             + ($f[$ptr+1])
             + 8;
        last if $idx < $ptr;
      } elsif $v gt $key {
        # Read right
        $ptr = $idx + 6;
        $idx = ($f[$ptr] +< 8)
             + ($f[$ptr+1])
             + 8;
        last if $idx < $ptr;
      }
    }

    Empty;
  }

  method gist() {
    "{$!value} -> {$!meta}"
  }

  method Str {
    "{$!value} -> {$!meta}"
  }
}

sub index(@meta) is export {
  my $root = BST.new(:root);
  for @meta -> $j {
    for $j<provides>.keys -> $provided {
      $root.insert($provided, $j<dist>);
    }
  }
  $root;
}

sub index-f(IO() $meta-json) is export {
  index(from-j($meta-json.slurp));
}
