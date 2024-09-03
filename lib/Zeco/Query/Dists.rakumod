unit module Zeco::Query::Dists;

use Digest::SHA1::Native;

use Zeco::DB;
use Zeco::Config;
use Zeco::Responses;
use Zeco::Util::Process;
use Zeco::Query::Groups;
use Zeco::Util::Process;
use Zeco::Util::Types;
use Zeco::Util::Json;

sub remove-dist(QRemoveDist $dist, $user --> Result) is export {
  constant $sql-r = q:to/EOS/;
    SELECT id, meta
    FROM dists
    WHERE dist = $1
      AND deleted = false;
  EOS

  constant $sql-u = q:to/EOS/;
    UPDATE dists
    SET deleted = true
    WHERE id = $1;
  EOS

  my $res = db.query($sql-r, $dist.dist).hash;
  return NotFound.new unless $res;
  my $meta = from-j($res<meta>);
  if $meta<auth> ne "zef:{$user<username>}" {
    my $gs = members-groups(QGroup.new(group => $meta<auth>.substr(4)));

    return InvalidAuth.new(:message("Invalid auth. User<{$user<username>}> is not a member of {$meta<auth>.substr(4)}"))
      if $gs.status != 200 || $gs.payload.grep({$_<username> eq $user<username>}).elems == 0;
  }

  db.query($sql-u, $res<id>);
  Success.new;
} 

sub ingest-upload(QIngestUpload $dist, $user --> Result) is export {
  constant $sql-i = q:to/EOS/;
    INSERT INTO dists (id,                dist, path, meta, deleted)
               VALUES (gen_random_uuid(), $1,   $2,   $3,   false)
    RETURNING id;
  EOS

  my $key = sha1-hex($dist.dist);
  my $gz-path = $*TMPDIR.add("$key.tgz");
  my $dist-path = $*TMPDIR.add($key);
  $gz-path.spurt($dist.dist, :bin);

  # Extract archive
  my ($sc, $out, $err) = proc('mkdir', $dist-path);
  ($sc, $out, $err) = proc('tar', 'xf', $gz-path, '-C', $dist-path);

  return UnableToExtractArchive.new(:message("Error extracting archive:\n$err"))
    if $sc != 0;

  # Find & parse META6.json
  my $meta = $dist-path.add("META6.json");
  if !$meta.f {
    return UnableToLocateMeta6.new if $dist-path.dir.elems != 1;
    $meta = $dist-path.add($dist-path.dir[0].relative($dist-path)).add('META6.json');
    return UnableToLocateMeta6.new(:message('No META6 found at: '~$meta))
      unless $meta.f;
  }

  $meta = try { from-j($meta.slurp) } // Any;

  return InvalidMeta6Json.new unless $meta;

  # Validate user|group & auth
  if $meta<auth> ne "zef:{$user<username>}" {
    # Check groups
    my $gs = members-groups(QGroup.new(group => $meta<auth>.substr(4)));

    return InvalidAuth.new(:message("Invalid auth. User<{$user<username>}> is not a member of {$meta<auth>.substr(4)}"))
      if $gs.status != 200 || $gs.payload.grep({$_<username> eq $user<username>}).elems == 0;
  }

  # todo: this needs to upload to s3, and save to db
  my $name = S:g/<-[A..Za..z0..9_]>+// given $meta<name>.uc.subst('::', '_', :global);
  return InvalidMeta6Json.new(:message('Please use a name containing at least one ascii character'))
    if $name.chars == 0;
  return InvalidMeta6Json.new(:message('Provides section in META6 is missing or invalid'))
    unless $meta<provides> ~~ Hash;
  my $path = sprintf '%s/', $name.substr(0, 1);
  $path ~= sprintf('%s/', $name.substr(1, 2)) if $name.chars >= 3;
  $path ~= sprintf '%s.tar.gz', $key;
  my $escaped-ver  = (S:g/(<+[<>]>)/\\$0/ given $meta<version>);
  my $escaped-auth = (S:g/(<+[<>]>)/\\$0/ given $meta<auth>);
  my $dist-name = $meta<name>
                ~ sprintf(':ver<%s>:auth<%s>', $escaped-ver, $escaped-auth);
  my $index-meta = {
    :$path,
    :version($meta<version>),
    :dist($dist-name),
    :provides($meta<provides>),
    :api($meta<api> // ''),
    :auth($meta<auth>),
    :name($meta<name>),
  };
  my ($rc, $pout, $perr) = config.bucket eq '<TEST>'
    ?? (0, Nil, Nil)
    !! proc('aws', 's3', 'mv', $gz-path.absolute, "{config.bucket}/repo/{$path}");

  return UnknownError.new(:message('Failed to send dist to permanent index, please try again in a few minutes'))
    unless $rc == 0;
  my $rval = db.query($sql-i, $dist-name, $path, to-j($index-meta)).hash;
  die 'Failed to index.' unless $rval<id>:exists;

  Success.new();
}

sub generate-full-meta(--> Result) is export {
  constant $sql-j = q:to/EOS/;
    SELECT meta
    FROM dists
    WHERE deleted = false
    ORDER BY created ASC;
  EOS

  MetaIndex.new: index => db.query($sql-j).hashes.map({from-j($_<meta>)}); 
}
