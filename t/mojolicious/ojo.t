use Mojo::Base -strict;

use utf8;

# Disable IPv6, libev and proxy detection
BEGIN {
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_PROXY}   = 0;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More tests => 11;

# "What do you mean 'we', flesh-tube?"
use ojo;

# * /
a(
  '/' => sub {
    my $self = shift;
    $self->render(text => $self->req->method . ($self->param('foo') || ''));
  }
);

# GET /
is g('/')->body, 'GET', 'right content';

# HEAD /
is h('/')->body, '', 'no content';

# OPTIONS /
is o('/')->body, 'OPTIONS', 'right content';

# PATCH /
is t('/')->body, 'PATCH', 'right content';

# POST /
is p('/')->body, 'POST', 'right content';

# PUT /
is u('/')->body, 'PUT', 'right content';

# DELETE /
is d('/')->body, 'DELETE', 'right content';

# POST / (form)
is f('/' => {foo => 'bar'})->body, 'POSTbar', 'right content';

# Parse XML
is x('<title>works</title>')->at('title')->text, 'works', 'right text';

# ByteStream
is b('<foo>')->url_escape, '%3Cfoo%3E', 'right result';

# Collection
is c(1, 2, 3)->join('-'), '1-2-3', 'right result';
