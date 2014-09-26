use Mojo::Base -strict;

use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new(max_keys => 2);
is $cache->get('foo'), undef, 'no result';
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), undef,  'no result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  undef,  'no result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';
$cache->max_keys(1)->set(one => 1)->set(two => 2);
is $cache->get('one'), undef, 'no result';
is $cache->get('two'), 2,     'right result';

$cache = Mojo::Cache->new(max_keys => 3);
is $cache->get('foo'), undef, 'no result';
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), 'bar',  'right result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  'baz',  'right result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';

# Zero max_key cache effectively turns caching off
$cache = Mojo::Cache->new(max_keys => 0);
is $cache->get('foo'), undef, 'no result';
$cache->set(foo => 'bar');
is $cache->get('foo'), undef, 'no result';
$cache->set(bar => 'baz');
is $cache->get('foo'), undef, 'no result';
is $cache->get('bar'), undef, 'no result';

# Negative max_key doesn't make sense, but we shouldn't get stuck in a loop
$cache = Mojo::Cache->new(max_keys => -1);
is $cache->get('foo'), undef, 'no result';
$cache->set(foo => 'bar');
is $cache->get('foo'), undef, 'no result';
$cache->set(bar => 'baz');
is $cache->get('foo'), undef, 'no result';
is $cache->get('bar'), undef, 'no result';

done_testing();
