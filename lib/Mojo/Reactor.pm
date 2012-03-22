package Mojo::Reactor;
use Mojo::Base 'Mojo::EventEmitter';

use IO::Poll qw/POLLERR POLLHUP POLLIN POLLOUT/;
use Mojo::Loader;
use Mojo::Util 'md5_sum';
use Time::HiRes qw/time usleep/;

# "I don't know.
#  Can I really betray my country?
#  I say the Pledge of Allegiance every day.
#  You pledge allegiance to the flag.
#  And the flag is made in China."
sub detect {
  my $try = $ENV{MOJO_REACTOR} || 'Mojo::Reactor::EV';
  return $try unless Mojo::Loader->load($try);
  return 'Mojo::Reactor';
}

sub drop {
  my ($self, $drop) = @_;
  return delete shift->{timers}->{shift()} unless ref $drop;
  $self->_poll->remove($drop);
  return delete $self->{io}->{fileno $drop};
}

sub io {
  my ($self, $handle, $cb) = @_;
  $self->{io}->{fileno $handle} = {cb => $cb};
  return $self->watch($handle, 1, 1);
}

sub is_readable {
  my ($self, $handle) = @_;

  my $test = $self->{test} ||= IO::Poll->new;
  $test->mask($handle, POLLIN);
  $test->poll(0);
  my $result = $test->handles(POLLIN | POLLERR | POLLHUP);
  $test->remove($handle);

  return !!$result;
}

sub is_running { shift->{running} }

# "This was such a pleasant St. Patrick's Day until Irish people showed up."
sub one_tick {
  my $self = shift;

  # Remember state
  my $running = $self->{running};
  $self->{running} = 1;

  # I/O
  my $poll = $self->_poll;
  $poll->poll(0.025);
  $self->_sandbox('Read', $self->{io}->{fileno $_}->{cb}, 0)
    for $poll->handles(POLLIN | POLLHUP | POLLERR);
  $self->_sandbox('Write', $self->{io}->{fileno $_}->{cb}, 1)
    for $poll->handles(POLLOUT);

  # Wait for timeout
  usleep 25000 unless keys %{$self->{io}};

  # Timers
  while (my ($id, $t) = each %{$self->{timers} || {}}) {
    my $after = $t->{after} || 0;
    if ($after <= time - ($t->{started} || $t->{recurring} || 0)) {

      # Normal timer
      if ($t->{started}) { $self->drop($id) }

      # Recurring timer
      elsif ($after && $t->{recurring}) { $t->{recurring} += $after }

      # Handle timer
      if (my $cb = $t->{cb}) { $self->_sandbox("Timer $id", $cb) }
    }
  }

  # Restore state if necessary
  $self->{running} = $running if $self->{running};
}

sub recurring { shift->_timer(pop, after => pop, recurring => time) }

sub start {
  my $self = shift;
  return if $self->{running}++;
  while ($self->{running}) {
    $self->one_tick;
    $self->stop unless keys(%{$self->{timers}}) || keys(%{$self->{io}});
  }
}

sub stop { delete shift->{running} }

# "Bart, how did you get a cellphone?
#  The same way you got me, by accident on a golf course."
sub timer { shift->_timer(pop, after => pop, started => time) }

sub watch {
  my ($self, $handle, $read, $write) = @_;

  my $poll = $self->_poll;
  $poll->remove($handle);
  if ($read && $write) { $poll->mask($handle, POLLIN | POLLOUT) }
  elsif ($read)  { $poll->mask($handle, POLLIN) }
  elsif ($write) { $poll->mask($handle, POLLOUT) }

  return $self;
}

sub _poll { shift->{poll} ||= IO::Poll->new }

sub _sandbox {
  my ($self, $desc, $cb) = (shift, shift, shift);
  return if eval { $self->$cb(@_); 1 };
  $self->once(error => sub { warn $_[1] })
    unless $self->has_subscribers('error');
  $self->emit_safe(error => "$desc failed: $@");
}

sub _timer {
  my ($self, $cb) = (shift, shift);

  my $t = {cb => $cb, @_};
  my $id;
  do { $id = md5_sum('t' . time . rand 999) } while $self->{timers}->{$id};
  $self->{timers}->{$id} = $t;

  return $id;
}

1;
__END__

=head1 NAME

Mojo::Reactor - Minimalistic low level event reactor

=head1 SYNOPSIS

  use Mojo::Reactor;

  # Watch if handle becomes readable or writable
  my $reactor = Mojo::Reactor->new;
  $reactor->io($handle => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'Handle is writable' : 'Handle is readable';
  });

  # Add a timer
  $reactor->timer(15 => sub {
    my $reactor = shift;
    $reactor->drop($handle);
    say 'Timeout!';
  });

  # Start reactor if necessary
  $reactor->start unless $reactor->is_running;

=head1 DESCRIPTION

L<Mojo::Reactor> is a minimalistic low level event reactor based on
L<IO::Poll> and the foundation of L<Mojo::IOLoop>. Note that this module is
EXPERIMENTAL and might change without warning!

  # A new reactor implementation could look like this
  package Mojo::Reactor::MyLoop;
  use Mojo::Base 'Mojo::Reactor';

  $ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::MyLoop';

  sub drop       {...}
  sub io         {...}
  sub is_running {...}
  sub one_tick   {...}
  sub recurring  {...}
  sub start      {...}
  sub stop       {...}
  sub timer      {...}
  sub watch      {...}

  1;

Exceptions in callbacks should be caught and emitted as C<error> events with
L<Mojo::EventEmitter/"emit">.

=head1 EVENTS

L<Mojo::Reactor> can emit the following events.

=head2 C<error>

  $reactor->on(error => sub {
    my ($reactor, $err) = @_;
    ...
  });

Emitted safely if an error happens.

  $reactor->on(error => sub {
    my ($reactor, $err) = @_;
    say "Something very bad happened: $err";
  });

=head1 METHODS

L<Mojo::Reactor> inherits all methods from L<Mojo::EventEmitter> and
implements the following new ones.

=head2 C<detect>

  my $class = Mojo::Reactor->detect;

Detect and load the best reactor implementation available, will try the value
of the C<MOJO_REACTOR> environment variable or L<Mojo::Reactor::EV>.

=head2 C<drop>

  my $success = $reactor->drop($handle);
  my $success = $reactor->drop($id);

Drop handle or timer.

=head2 C<io>

  $reactor = $reactor->io($handle => sub {...});

Watch handle for I/O events, invoking the callback whenever handle becomes
readable or writable.

  # Callback will be invoked twice if handle becomes readable and writable
  $reactor->io($handle => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'Handle is writable' : 'Handle is readable';
  });

=head2 C<is_readable>

  my $success = $reactor->is_readable($handle);

Quick check if a handle is readable, useful for identifying tainted
sockets.

=head2 C<is_running>

  my $success = $reactor->is_running;

Check if reactor is running.

=head2 C<one_tick>

  $reactor->one_tick;

Run reactor for roughly one tick. Note that this method can recurse back into
the reactor, so you need to be careful.

=head2 C<recurring>

  my $id = $reactor->recurring(0.25 => sub {...});

Create a new recurring timer, invoking the callback repeatedly after a given
amount of time in seconds.

  # Invoke as soon as possible
  $reactor->recurring(0 => sub { say 'Reactor tick.' });

=head2 C<start>

  $reactor->start;

Start watching for I/O and timer events, this will block until C<stop> is
called or no events are being watched anymore.

=head2 C<stop>

  $reactor->stop;

Stop watching for I/O and timer events.

=head2 C<timer>

  my $id = $reactor->timer(0.5 => sub {...});

Create a new timer, invoking the callback after a given amount of time in
seconds.

=head2 C<watch>

  $reactor = $reactor->watch($handle, $readable, $writable);

Change I/O events to watch handle for with C<true> and C<false> values.

  # Watch only for readable events
  $reactor->watch($handle, 1, 0);

  # Watch only for writable events
  $reactor->watch($handle, 0, 1);

  # Watch for readable and writable events
  $reactor->watch($handle, 1, 1);

  # Pause watching for events
  $reactor->watch($handle, 0, 0);

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
