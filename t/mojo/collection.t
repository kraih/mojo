#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 40;

# "'What are you lookin at?' - the innocent words of a drunken child."
use_ok 'Mojo::Collection', 'c';

# each
my $collection = c(3, 2, 1);
is_deeply [$collection->each], [3, 2, 1], 'right elements';
$collection = c([3], [2], [1]);
my @results;
$collection->each(sub { push @results, $_->[0] });
is_deeply \@results, [3, 2, 1], 'right elements';
@results = ();
$collection->each(sub { push @results, shift->[0], shift });
is_deeply \@results, [3, 1, 2, 2, 1, 3], 'right elements';

# first
$collection = c(5, 4, [3, 2], 1);
is $collection->first, 5, 'right result';
is_deeply $collection->first(sub { ref $_ eq 'ARRAY' }), [3, 2],
  'right result';
is $collection->first(sub { shift() < 5 }), 4, 'right result';
is $collection->first(sub { ref $_ eq 'CODE' }), undef, 'no result';
$collection = c();
is $collection->first, undef, 'no result';
is $collection->first(sub { defined $_ }), undef, 'no result';

# grep
$collection = c(1, 2, 3, 4, 5, 6, 7, 8, 9);
is_deeply [$collection->grep(sub { $_ > 5 })->each], [6, 7, 8, 9],
  'right elements';
is_deeply [$collection->grep(sub { $_ < 5 })->each], [1, 2, 3, 4],
  'right elements';
is_deeply [$collection->grep(sub { shift == 5 })->each], [5],
  'right elements';
is_deeply [$collection->grep(sub { $_ < 1 })->each], [], 'no elements';
is_deeply [$collection->grep(sub { $_ > 9 })->each], [], 'no elements';

# join
$collection = c(1, 2, 3);
is $collection->join(''),    '123',       'right result';
is $collection->join('---'), '1---2---3', 'right result';
is $collection->join("\n"),  "1\n2\n3",   'right result';
is $collection->join('/')->url_escape, '1%2F2%2F3', 'right result';
$collection = c(c(1, 2, 3), c(3, 2, 1));
is $collection->join(''), "1\n2\n33\n2\n1", 'right result';

# map
$collection = c(1, 2, 3);
is $collection->map(sub { $_ + 1 })->join(''), '234', 'right result';
is_deeply [@$collection], [1, 2, 3], 'right elements';
is $collection->map(sub { shift() + 2 })->join(''), '345', 'right result';
is_deeply [@$collection], [1, 2, 3], 'right elements';

# reverse
$collection = c(3, 2, 1);
is_deeply [$collection->reverse->each], [1, 2, 3], 'right order';
$collection = c(3);
is_deeply [$collection->reverse->each], [3], 'right order';
$collection = c();
is_deeply [$collection->reverse->each], [], 'no elements';

# shuffle
$collection = c(0 .. 10000);
my $random = $collection->shuffle;
is $collection->size, $random->size, 'same number of elements';
isnt "@$collection", "@$random", 'different order';
is_deeply [c()->shuffle->each], [], 'no elements';

# size
$collection = c();
is $collection->size, 0, 'right size';
$collection = c(undef);
is $collection->size, 1, 'right size';
$collection = c(23);
is $collection->size, 1, 'right size';
$collection = c([2, 3]);
is $collection->size, 1, 'right size';
$collection = c(5, 4, 3, 2, 1);
is $collection->size, 5, 'right size';

# sort
$collection = c(2, 5, 4, 1);
is_deeply [$collection->sort->each], [1, 2, 4, 5], 'right order';
is_deeply [$collection->sort(sub { $_[1] cmp $_[0] })->each], [5, 4, 2, 1],
  'right order';
$collection = c(qw/Test perl Mojo/);
is_deeply [$collection->sort(sub { uc(shift) cmp uc(shift) })->each],
  [qw/Mojo perl Test/], 'right order';
$collection = c();
is_deeply [$collection->sort->each], [], 'no elements';
is_deeply [$collection->sort(sub { $_[1] cmp $_[0] })->each], [],
  'no elements';
