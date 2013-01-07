package Mojo::Path;
use Mojo::Base -base;
use overload
  'bool'   => sub {1},
  '""'     => sub { shift->to_string },
  fallback => 1;

use Mojo::Util qw(decode encode url_escape url_unescape);

has charset => 'UTF-8';
has [qw(leading_slash trailing_slash)];
has parts => sub { [] };

sub new { shift->SUPER::new->parse(@_) }

sub canonicalize {
  my $self = shift;

  # Resolve path
  my @parts;
  for my $part (@{$self->parts}) {

    # ".."
    if ($part eq '..') {
      unless (@parts && $parts[-1] ne '..') { push @parts, '..' }
      else                                  { pop @parts }
      next;
    }

    # "."
    next if grep { $_ eq $part } '.', '';

    # Part
    push @parts, $part;
  }
  $self->trailing_slash(undef) unless @parts;

  return $self->parts(\@parts);
}

sub clone {
  my $self  = shift;
  my $clone = Mojo::Path->new;
  $clone->leading_slash($self->leading_slash);
  $clone->trailing_slash($self->trailing_slash);
  return $clone->charset($self->charset)->parts([@{$self->parts}]);
}

sub contains {
  my ($self, $path) = @_;

  my $parts = $self->new($path)->parts;
  for my $part (@{$self->parts}) {
    return 1 unless defined(my $try = shift @$parts);
    return undef unless $part eq $try;
  }

  return !@$parts;
}

sub merge {
  my ($self, $path) = @_;

  # Replace
  return $self->parse($path) if $path =~ m!^/!;

  # Merge
  pop @{$self->parts} unless $self->trailing_slash;
  $path = $self->new($path);
  push @{$self->parts}, @{$path->parts};
  return $self->trailing_slash($path->trailing_slash);
}

sub parse {
  my ($self, $path) = @_;

  $path = url_unescape $path // '';
  my $charset = $self->charset;
  $path = decode($charset, $path) // $path if $charset;
  $self->leading_slash($path =~ s!^/!!  ? 1 : undef);
  $self->trailing_slash($path =~ s!/$!! ? 1 : undef);

  return $self->parts([split '/', $path, -1]);
}

sub to_abs_string { $_[0]->leading_slash ? "$_[0]" : "/$_[0]" }

sub to_route {
  my $self = shift;
  return '/' . join('/', @{$self->parts}) . ($self->trailing_slash ? '/' : '');
}

sub to_string {
  my $self = shift;

  my @parts   = @{$self->parts};
  my $charset = $self->charset;
  @parts = map { encode $charset, $_ } @parts if $charset;
  my $path = join '/',
    map { url_escape $_, '^A-Za-z0-9\-._~!$&\'()*+,;=:@' } @parts;
  $path = "/$path" if $self->leading_slash;
  $path = "$path/" if $self->trailing_slash;

  return $path;
}

1;

=encoding utf8

=head1 NAME

Mojo::Path - Path

=head1 SYNOPSIS

  use Mojo::Path;

  my $path = Mojo::Path->new('/foo%2Fbar%3B/baz.html');
  shift @{$path->parts};
  say "$path";

=head1 DESCRIPTION

L<Mojo::Path> is a container for URL paths.

=head1 ATTRIBUTES

L<Mojo::Path> implements the following attributes.

=head2 charset

  my $charset = $path->charset;
  $path       = $path->charset('UTF-8');

Charset used for encoding and decoding, defaults to C<UTF-8>.

  # Disable encoding and decoding
  $path->charset(undef);

=head2 leading_slash

  my $leading_slash = $path->leading_slash;
  $path             = $path->leading_slash(1);

Path has a leading slash.

=head2 parts

  my $parts = $path->parts;
  $path     = $path->parts([qw(foo bar baz)]);

The path parts.

  # Part with slash
  push @{$path->parts}, 'foo/bar';

=head2 trailing_slash

  my $trailing_slash = $path->trailing_slash;
  $path              = $path->trailing_slash(1);

Path has a trailing slash.

=head1 METHODS

L<Mojo::Path> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 new

  my $path = Mojo::Path->new;
  my $path = Mojo::Path->new('/foo%2Fbar%3B/baz.html');

Construct a new L<Mojo::Path> object.

=head2 canonicalize

  $path = $path->canonicalize;

Canonicalize path.

  # "/foo/baz"
  Mojo::Path->new('/foo/bar/../baz')->canonicalize;

=head2 clone

  my $clone = $path->clone;

Clone path.

=head2 contains

  my $success = $path->contains('/foo');

Check if path contains given prefix.

  # True
  Mojo::Path->new('/foo/bar')->contains('/');
  Mojo::Path->new('/foo/bar')->contains('/foo');
  Mojo::Path->new('/foo/bar')->contains('/foo/bar');

  # False
  Mojo::Path->new('/foo/bar')->contains('/f');
  Mojo::Path->new('/foo/bar')->contains('/bar');
  Mojo::Path->new('/foo/bar')->contains('/whatever');

=head2 merge

  $path = $path->merge('/foo/bar');
  $path = $path->merge('foo/bar');
  $path = $path->merge(Mojo::Path->new('foo/bar'));

Merge paths.

  # "/baz/yada"
  Mojo::Path->new('/foo/bar')->merge('/baz/yada');

  # "/foo/baz/yada"
  Mojo::Path->new('/foo/bar')->merge('baz/yada');

  # "/foo/bar/baz/yada"
  Mojo::Path->new('/foo/bar/')->merge('baz/yada');

=head2 parse

  $path = $path->parse('/foo%2Fbar%3B/baz.html');

Parse path. Note that C<%2F> will be treated as C</> for security reasons.

=head2 to_abs_string

  my $string = $path->to_abs_string;

Turn path into an absolute string.

=head2 to_route

  my $route = $path->to_route;

Turn path into a route.

  # "/i/♥/mojolicious"
  Mojo::Path->new('/i/%E2%99%A5/mojolicious')->to_route;

=head2 to_string

  my $string = $path->to_string;
  my $string = "$path";

Turn path into a string.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
