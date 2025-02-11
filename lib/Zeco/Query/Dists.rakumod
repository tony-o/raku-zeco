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

=begin pod

=NAME
Zeco::Query::Dists

=begin SYNOPSIS
Methods for handling the processes around dist management.
=end SYNOPSIS

=head2 method remove-dist(QRemoveDist, $user --> Result)

  Signature: QRemoveDist - the dist to be removed
             $user       - hash of the pre-authed user
  Returns: a Result object.

  Returns NotFound if the delete window is past or the dist is not found in the
  current index. Returns InvalidAuth if the user does not have permission to
  remove the dist.  Success otherwise.

  This method is intended to remove the dist from the `dists` table when the
  config value `delete-window` (in hours) has not passed, or when the value is
  less than zero. If the config value is zero then a dist can be removed any
  time.

=head2 method ingest-upload(QIngestUpload, $user --> Result)
  
  Signature: QIngestUpload - the dist to be indexed 
             $user         - hash of the pre-authed user
  Returns: a Result object

  Does several checks against the dist:
  
  - Verify the dist can be extracted by standard tooling
    -> UnableToExtractArchive
  - Ensures a META6.json file is present and can be parsed by raku's JSON
    internal methods -> UnableToLocateMeta6
  - Confirms user is a member of the group in the META6's auth or is the
    use in the auth -> InvalidAuth
  - Makes sure the dist name contains at least one a-z0-9 character
    -> InvalidMeta6Json
  - Ensures a `provides` section is there (does not verify contents)
    -> InvalidMeta6Json
  - Runs a script specified by the config to do something with the index
    -> IndexFailed (TODO)
  - Returns Success

  After the checks this will attempt to run the command in
  config.dist-move-command as follows:

  config.dist-move-command <path to .tar.tz> <expected path at destination>

=head2 method generate-full-meta(--> Result)
  
  Returns: MetaIndex 

  Retrieves all non-deleted dists from the `dists` table and returns them in a
  nicely typed object (as a list).

=end pod

sub remove-dist(QRemoveDist $dist, $user --> Result) is export {
  constant $sql-r = q:to/EOS/;
    SELECT id, meta
    FROM dists
    WHERE dist = $1
      AND EXTRACT(EPOCH FROM created) > $2
      AND deleted IS NULL;
  EOS

  constant $sql-u = q:to/EOS/;
    UPDATE dists
    SET deleted = now() 
    WHERE id = $1;
  EOS

  return NotFound.new if config.delete-window < 0;

  my $res = db.query($sql-r, $dist.dist, config.delete-window > 0 ?? DateTime.now().posix - (3600 * config.delete-window) !! 0).hash;
  return NotFound.new unless $res;
  my $meta = from-j($res<meta>);
  if $meta<auth> ne "{config.eco-prefix}:{$user<username>}" {
    my $gs = members-groups(QGroup.new(group => $meta<auth>.substr(config.eco-prefix.chars + 1)));

    return InvalidAuth.new(:message("Invalid auth. User<{config.eco-prefix}:{$user<username>}> is not a member of {$meta<auth>}"))
      if $gs.status != 200 || $gs.payload.grep({$_<username> eq $user<username>}).elems == 0;
  }

  db.query($sql-u, $res<id>);
  Success.new;
} 

sub ingest-upload(QIngestUpload $dist, $user --> Result) is export {
  constant $sql-i = q:to/EOS/;
    INSERT INTO dists (id,                dist, path, meta)
               VALUES (gen_random_uuid(), $1,   $2,   $3)
    RETURNING id;
  EOS
  constant $sql-s = q:to/EOS/;
    SELECT id FROM dists WHERE dist = $1 LIMIT 1;
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
  return InvalidAuth.new(:message("Invalid auth: {$meta<auth>}"))
    if $meta<auth>.substr(0, config.eco-prefix.chars) ne config.eco-prefix;
  if $meta<auth> ne "{config.eco-prefix}:{$user<username>}" {
    # Check groups
    my $gs = members-groups(QGroup.new(group => $meta<auth>.substr(config.eco-prefix.chars + 1)));

    return InvalidAuth.new(:message("Invalid auth. User<{config.eco-prefix}:{$user<username>}> is not a member of {$meta<auth>}"))
      if $gs.status != 200 || $gs.payload.grep({$_<username> eq $user<username>}).elems == 0;
  }

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
  my $index-meta = $meta;
  $index-meta<path> = "/dist/{$path}";
  $index-meta<dist> = $dist-name;
  $index-meta<source-url>:delete;

  my $existing-dist = db.query($sql-s, $dist-name).array;

  return DistExists.new if $existing-dist.elems > 0;

  my ($rc, $pout, $perr) = proc(|config.dist-move-command, $gz-path.absolute, $path);

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
    WHERE deleted IS NULL
    ORDER BY created ASC;
  EOS

  MetaIndex.new: index => db.query($sql-j).hashes.map({from-j($_<meta>)}); 
}
