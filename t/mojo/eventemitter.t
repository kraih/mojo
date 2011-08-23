#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 36;

# "Hi, Super Nintendo Chalmers!"
use_ok 'Mojo::IOLoop::EventEmitter';

# Normal event
my $e      = Mojo::IOLoop::EventEmitter->new;
my $called = 0;
$e->on(test1 => sub { $called++ });
$e->emit('test1');
is $called, 1, 'event was emitted once';

# Error fallback
my ($echo, $error);
$e->on(error => sub { $error = pop });
$e->on(test2 => sub { $echo .= 'echo: ' . pop });
$e->on(
  test2 => sub {
    my ($self, $message) = @_;
    die "test2: $message\n";
  }
);
my $cb = sub { $echo .= 'echo2: ' . pop };
$e->on(test2 => $cb);
$e->emit('test2', 'works!');
is $echo, 'echo: works!echo2: works!', 'right echo';
is $error, qq/Event "test2" failed: test2: works!\n/, 'right error';
$echo = $error = undef;
is scalar @{$e->subscribers('test2')}, 3, 'three subscribers';
$e->unsubscribe(test2 => $cb);
is scalar @{$e->subscribers('test2')}, 2, 'two subscribers';
$e->emit('test2', 'works!');
is $echo, 'echo: works!', 'right echo';
is $error, qq/Event "test2" failed: test2: works!\n/, 'right error';

# Normal event again
$e->emit('test1');
is $called, 2, 'event was emitted twice';
is scalar @{$e->subscribers('test1')}, 1, 'one subscriber';
$e->emit('test1');
$e->unsubscribe(test1 => $e->subscribers('test1')->[0]);
is $called, 3, 'event was emitted three times';
is scalar @{$e->subscribers('test1')}, 0, 'no subscribers';
$e->emit('test1');
is $called, 3, 'event was not emitted again';
$e->emit('test1');
is $called, 3, 'event was not emitted again';

# One time event
my $once = 0;
$e->once(one_time => sub { $once++ });
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 1, 'event was emitted once';
is scalar @{$e->subscribers('one_time')}, 0, 'no subscribers';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';

# Nested one time events
$once = 0;
$e->once(
  one_time => sub {
    $e->once(
      one_time => sub {
        $e->once(one_time => sub { $once++ });
      }
    );
  }
);
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 0, 'only first event was emitted';
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 0, 'only second event was emitted';
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 1, 'third event was emitted';
is scalar @{$e->subscribers('one_time')}, 0, 'no subscribers';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';

# Unsubscribe
$e = Mojo::IOLoop::EventEmitter->new;
my $counter = 0;
$cb = $e->on(foo => sub { $counter++ });
$e->on(foo => sub { $counter++ });
$e->on(foo => sub { $counter++ });
$e->unsubscribe(foo => $e->once(foo => sub { $counter++ }));
is scalar @{$e->subscribers('foo')}, 3, 'three subscribers';
$e->emit('foo');
is $counter, 3, 'event was emitted three times';
$e->unsubscribe(foo => $cb);
is scalar @{$e->subscribers('foo')}, 2, 'two subscribers';
$e->emit('foo');
is $counter, 5, 'event was emitted two times';
$e->unsubscribe(foo => $_) for @{$e->subscribers('foo')};
is scalar @{$e->subscribers('foo')}, 0, 'no subscribers';
$e->emit('foo');
is $counter, 5, 'event was not emitted again';
