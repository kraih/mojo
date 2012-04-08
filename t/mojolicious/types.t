use Mojo::Base -strict;

use Test::More tests => 30;

# "Your mistletoe is no match for my *tow* missile."
use Mojolicious::Types;

# Basics
my $t = Mojolicious::Types->new;
is $t->type('json'), 'application/json', 'right type';
is $t->type('foo'), undef, 'no type';
$t->type(foo => 'foo/bar');
is $t->type('foo'), 'foo/bar', 'right type';

# Detect common MIME types
is_deeply $t->detect('application/atom+xml'),     ['atom'], 'right formats';
is_deeply $t->detect('application/octet-stream'), ['bin'],  'right formats';
is_deeply $t->detect('text/css'),                 ['css'],  'right formats';
is_deeply $t->detect('image/gif'),                ['gif'],  'right formats';
is_deeply $t->detect('application/gzip'),         ['gz'],   'right formats';
is_deeply $t->detect('text/html'), ['htm', 'html'], 'right formats';
is_deeply $t->detect('image/x-icon'), ['ico'], 'right formats';
is_deeply $t->detect('image/jpeg'), ['jpeg', 'jpg'], 'right formats';
is_deeply $t->detect('application/x-javascript'), ['js'],   'right formats';
is_deeply $t->detect('application/json'),         ['json'], 'right formats';
is_deeply $t->detect('audio/mpeg'),               ['mp3'],  'right formats';
is_deeply $t->detect('application/pdf'),          ['pdf'],  'right formats';
is_deeply $t->detect('image/png'),                ['png'],  'right formats';
is_deeply $t->detect('application/rss+xml'),      ['rss'],  'right formats';
is_deeply $t->detect('image/svg+xml'),            ['svg'],  'right formats';
is_deeply $t->detect('application/x-tar'),        ['tar'],  'right formats';
is_deeply $t->detect('text/plain'),               ['txt'],  'right formats';
is_deeply $t->detect('application/x-font-woff'),  ['woff'], 'right formats';
is_deeply $t->detect('text/xml'), ['xml', 'xsl'], 'right formats';
is_deeply $t->detect('application/zip'), ['zip'], 'right format';

# Detect special cases
is_deeply $t->detect('Text/Xml'),        ['xml', 'xsl'],  'right formats';
is_deeply $t->detect('TEXT/XML'),        ['xml', 'xsl'],  'right formats';
is_deeply $t->detect('text/html;q=0.9'), ['htm', 'html'], 'right formats';
is_deeply $t->detect('text/html,*/*'),             [], 'no formats';
is_deeply $t->detect('text/html;q=0.9,*/*'),       [], 'no formats';
is_deeply $t->detect('text/html,*/*;q=0.9'),       [], 'no formats';
is_deeply $t->detect('text/html;q=0.8,*/*;q=0.9'), [], 'no formats';
