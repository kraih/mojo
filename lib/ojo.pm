package ojo;
use Mojo::Base -strict;

# "I heard beer makes you stupid.
#  No I'm... doesn't."
use Mojo::ByteStream 'b';
use Mojo::Collection 'c';
use Mojo::DOM;
use Mojo::UserAgent;

# Silent oneliners
$ENV{MOJO_LOG_LEVEL} ||= 'fatal';

# User agent
my $UA = Mojo::UserAgent->new;

# "I'm sorry, guys. I never meant to hurt you.
#  Just to destroy everything you ever believed in."
sub import {

  # Prepare exports
  my $caller = caller;
  no strict 'refs';
  no warnings 'redefine';

  # Executable
  $ENV{MOJO_EXE} ||= (caller)[1];

  # Mojolicious::Lite
  eval "package $caller; use Mojolicious::Lite;";

  # Allow redirects
  $UA->max_redirects(1) unless defined $ENV{MOJO_MAX_REDIRECTS};

  # Application
  $UA->app(*{"${caller}::app"}->());

  # Functions
  *{"${caller}::Oo"} = *{"${caller}::b"} = \&b;
  *{"${caller}::c"} = \&c;
  *{"${caller}::oO"} = sub { _request(@_) };
  *{"${caller}::a"} =
    sub { *{"${caller}::any"}->(@_) and return *{"${caller}::app"}->() };
  *{"${caller}::d"} = sub { _request('delete',    @_) };
  *{"${caller}::f"} = sub { _request('post_form', @_) };
  *{"${caller}::g"} = sub { _request('get',       @_) };
  *{"${caller}::h"} = sub { _request('head',      @_) };
  *{"${caller}::p"} = sub { _request('post',      @_) };
  *{"${caller}::u"} = sub { _request('put',       @_) };
  *{"${caller}::x"} = sub { Mojo::DOM->new(@_) };
}

# "I wonder what the shroud of Turin tastes like."
sub _request {

  # Method
  my $method = $_[0] =~ /:|\// ? 'get' : lc shift;

  # Transaction
  my $tx =
      $method eq 'post_form'
    ? $UA->build_form_tx(@_)
    : $UA->build_tx($method, @_);

  # Process
  $tx = $UA->start($tx);

  # Error
  my ($message, $code) = $tx->error;
  warn qq/Problem loading URL "$_[0]". ($message)\n/ if $message && !$code;

  return $tx->res;
}

1;
__END__

=head1 NAME

ojo - Fun Oneliners With Mojo!

=head1 SYNOPSIS

  perl -Mojo -e 'b(g("mojolicio.us")->dom->at("title")->text)->say'

=head1 DESCRIPTION

A collection of automatically exported functions for fun Perl oneliners.

=head1 FUNCTIONS

L<ojo> implements the following functions.

=head2 C<a>

  my $app = a('/' => sub { shift->render(json => {hello => 'world'}) });

Create a L<Mojolicious::Lite> route accepting all request methods and return
the application.

  perl -Mojo -e 'a("/" => {text => "Hello Mojo!"})->start' daemon

=head2 C<b>

  my $stream = b('lalala');

Turn string into a L<Mojo::ByteStream> object.

  perl -Mojo -e 'b(g("mojolicio.us")->body)->html_unescape->say'

=head2 C<c>

  my $collection = c(1, 2, 3);

Turn list into a L<Mojo::Collection> object.
Note that this function is EXPERIMENTAL and might change without warning!

=head2 C<d>

  my $res = d('http://mojolicio.us');
  my $res = d('http://mojolicio.us', {'X-Bender' => 'X_x'});
  my $res = d(
      'http://mojolicio.us',
      {'Content-Type' => 'text/plain'},
      'Hello!'
  );

Perform C<DELETE> request and turn response into a L<Mojo::Message::Response>
object.

=head2 C<f>

  my $res = f('http://kraih.com/foo' => {test => 123});
  my $res = f('http://kraih.com/foo', 'UTF-8', {test => 123});
  my $res = f(
    'http://kraih.com/foo',
    {test => 123},
    {'Content-Type' => 'multipart/form-data'}
  );
  my $res = f(
    'http://kraih.com/foo',
    'UTF-8',
    {test => 123},
    {'Content-Type' => 'multipart/form-data'}
  );
  my $res = f('http://kraih.com/foo', {file => {file => '/foo/bar.txt'}});
  my $res = f('http://kraih.com/foo', {file => {content => 'lalala'}});
  my $res = f(
    'http://kraih.com/foo',
    {myzip => {file => $asset, filename => 'foo.zip'}}
  );

Perform a C<POST> request for a form and turn response into a
L<Mojo::Message::Response> object.

=head2 C<g>

  my $res = g('http://mojolicio.us');
  my $res = g('http://mojolicio.us', {'X-Bender' => 'X_x'});
  my $res = g(
    'http://mojolicio.us',
    {'Content-Type' => 'text/plain'},
    'Hello!'
  );

Perform C<GET> request and turn response into a L<Mojo::Message::Response>
object.
One redirect will be followed by default, you can change this behavior with
the C<MOJO_MAX_REDIRECTS> environment variable.

  MOJO_MAX_REDIRECTS=0 perl -Mojo -e 'b(g("mojolicio.us")->code)->say'

=head2 C<h>

  my $res = h('http://mojolicio.us');
  my $res = h('http://mojolicio.us', {'X-Bender' => 'X_x'});
  my $res = h(
    'http://mojolicio.us',
    {'Content-Type' => 'text/plain'},
    'Hello!'
  );

Perform C<HEAD> request and turn response into a L<Mojo::Message::Response>
object.

=head2 C<p>

  my $res = p('http://mojolicio.us');
  my $res = p('http://mojolicio.us', {'X-Bender' => 'X_x'});
  my $res = p(
    'http://mojolicio.us',
    {'Content-Type' => 'text/plain'},
    'Hello!'
  );

Perform C<POST> request and turn response into a L<Mojo::Message::Response>
object.

=head2 C<u>

  my $res = u('http://mojolicio.us');
  my $res = u('http://mojolicio.us', {'X-Bender' => 'X_x'});
  my $res = u(
    'http://mojolicio.us',
    {'Content-Type' => 'text/plain'},
    'Hello!'
  );

Perform C<PUT> request and turn response into a L<Mojo::Message::Response>
object.

=head2 C<x>

  my $dom = x('<div>Hello!</div>');

Turn HTML5/XML input into L<Mojo::DOM> object.

  print x('<div>Hello!</div>')->at('div')->text;

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
