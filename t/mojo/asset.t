use Mojo::Base -strict;

use Test::More tests => 59;
use File::Temp;

# "And now, in the spirit of the season: start shopping.
#  And for every dollar of Krusty merchandise you buy,
#  I will be nice to a sick kid.
#  For legal purposes, sick kids may include hookers with a cold."
use_ok 'Mojo::Asset::File';
use_ok 'Mojo::Asset::Memory';

# File asset
my $file = Mojo::Asset::File->new;
$file->add_chunk('abc');
is $file->contains(''),    0,  'empty string at position 0';
is $file->contains('abc'), 0,  '"abc" at position 0';
is $file->contains('bc'),  1,  '"bc" at position 1';
is $file->contains('db'),  -1, 'does not contain "db"';

# Cleanup
my $path = $file->path;
ok -e $path, 'temporary file exists';
undef $file;
ok !-e $path, 'temporary file has been cleaned up';

# Memory asset
my $mem = Mojo::Asset::Memory->new;
$mem->add_chunk('abc');
is $mem->contains(''),    0,  'empty string at position 0';
is $mem->contains('abc'), 0,  '"abc" at position 0';
is $mem->contains('bc'),  1,  '"bc" at position 1';
is $mem->contains('db'),  -1, 'does not contain "db"';

# Empty file asset
$file = Mojo::Asset::File->new;
is $file->contains(''), 0, 'empty string at position 0';

# Empty memory asset
$mem = Mojo::Asset::File->new;
is $mem->contains(''), 0, 'empty string at position 0';

# File asset range support (a[bcdef])
$file = Mojo::Asset::File->new(start_range => 1);
$file->add_chunk('abcdef');
is $file->contains(''),      0,  'empty string at position 0';
is $file->contains('bcdef'), 0,  '"bcdef" at position 0';
is $file->contains('cdef'),  1,  '"cdef" at position 1';
is $file->contains('db'),    -1, 'does not contain "db"';

# Memory asset range support (a[bcdef])
$mem = Mojo::Asset::Memory->new(start_range => 1);
$mem->add_chunk('abcdef');
is $mem->contains(''),      0,  'empty string at position 0';
is $mem->contains('bcdef'), 0,  '"bcdef" at position 0';
is $mem->contains('cdef'),  1,  '"cdef" at position 1';
is $mem->contains('db'),    -1, 'does not contain "db"';

# File asset range support (ab[cdefghi]jk)
{
  local $ENV{MOJO_CHUNK_SIZE} = 1024;
  $file = Mojo::Asset::File->new(start_range => 2, end_range => 8);
  $file->add_chunk('abcdefghijk');
  is $file->contains(''),        0,  'empty string at position 0';
  is $file->contains('cdefghi'), 0,  '"cdefghi" at position 0';
  is $file->contains('fghi'),    3,  '"fghi" at position 3';
  is $file->contains('f'),       3,  '"f" at position 3';
  is $file->contains('hi'),      5,  '"hi" at position 5';
  is $file->contains('db'),      -1, 'does not contain "db"';
  my $chunk = $file->get_chunk(0);
  is $chunk, 'cdefghi', 'chunk from position 0';
  $chunk = $file->get_chunk(1);
  is $chunk, 'defghi', 'chunk from position 1';
  $chunk = $file->get_chunk(5);
  is $chunk, 'hi', 'chunk from position 5';
  $ENV{MOJO_CHUNK_SIZE} = 1;
  $chunk = $file->get_chunk(0);
  is $chunk, 'c', 'chunk from position 0 with size 1';
  $chunk = $file->get_chunk(5);
  is $chunk, 'h', 'chunk from position 5 with size 1';
}

# Memory asset range support (ab[cdefghi]jk)
{
  local $ENV{MOJO_CHUNK_SIZE} = 1024;
  $mem = Mojo::Asset::Memory->new(start_range => 2, end_range => 8);
  $mem->add_chunk('abcdefghijk');
  is $mem->contains(''),        0,  'empty string at position 0';
  is $mem->contains('cdefghi'), 0,  '"cdefghi" at position 0';
  is $mem->contains('fghi'),    3,  '"fghi" at position 3';
  is $mem->contains('f'),       3,  '"f" at position 3';
  is $mem->contains('hi'),      5,  '"hi" at position 5';
  is $mem->contains('db'),      -1, 'does not contain "db"';
  my $chunk = $mem->get_chunk(0);
  is $chunk, 'cdefghi', 'chunk from position 0';
  $chunk = $mem->get_chunk(1);
  is $chunk, 'defghi', 'chunk from position 1';
  $chunk = $mem->get_chunk(5);
  is $chunk, 'hi', 'chunk from position 5';
  $ENV{MOJO_CHUNK_SIZE} = 1;
  $chunk = $mem->get_chunk(0);
  is $chunk, 'c', 'chunk from position 0 with size 1';
  $chunk = $mem->get_chunk(5);
  is $chunk, 'h', 'chunk from position 5 with size 1';
}

# Move memory asset to file
$mem = Mojo::Asset::Memory->new;
$mem->add_chunk('abc');
my $tmp = Mojo::Asset::File->new;
$tmp->add_chunk('x');
$mem->move_to($tmp->path);
is $mem->slurp, 'abc', 'right content';
undef $tmp;

# Move file asset to file
$file = Mojo::Asset::File->new;
$file->add_chunk('bcd');
$tmp = Mojo::Asset::File->new;
$tmp->add_chunk('x');
$file->move_to($tmp->path);
is $file->slurp, 'bcd', 'right content';
undef $tmp;

# Upgrade
my $asset = Mojo::Asset::Memory->new(max_memory_size => 5, auto_upgrade => 1);
$asset = $asset->add_chunk('lala');
ok !$asset->is_file, 'stored in memory';
$asset = $asset->add_chunk('lala');
ok $asset->is_file, 'stored in file';
$asset = Mojo::Asset::Memory->new(max_memory_size => 5);
$asset = $asset->add_chunk('lala');
ok !$asset->is_file, 'stored in memory';
$asset = $asset->add_chunk('lala');
ok !$asset->is_file, 'stored in memory';

# Temporary directory
{
  local $ENV{MOJO_TMPDIR} = '/does/not/exist';
  is(Mojo::Asset::File->new->tmpdir, '/does/not/exist', 'right value');
}

# Temporary file without cleanup
$file = Mojo::Asset::File->new(cleanup => 0)->add_chunk('test');
ok $file->is_file, 'stored in file';
is $file->slurp,   'test', 'right content';
is $file->size,    4, 'right size';
is $file->contains('es'), 1, '"es" at position 1';
$path = $file->path;
undef $file;
ok -e $path, 'file exists';
unlink $path;
ok !-e $path, 'file has been cleaned up';

# Failed syswrite
{
    no strict 'refs';
    # Fake ENOSPC : No space left on device
    *{"IO::File::syswrite"} = sub { $! = 28; return undef };
}
my $dir = File::Temp::tempdir(CLEANUP => 1);
my $mem_fail = Mojo::Asset::Memory->new;
$mem_fail->add_chunk('scooby doo');
eval {
    $mem_fail->move_to("$dir/tempfile");
};
ok $@, 'move_to failed because syswrite failed';
ok $@ =~ /move memory asset/, 'error message contains "move memory asset"';
