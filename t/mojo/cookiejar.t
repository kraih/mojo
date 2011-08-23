#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 34;

# "Hello, my name is Mr. Burns. I believe you have a letter for me.
#  Okay Mr. Burns, what’s your first name.
#  I don’t know."
use_ok 'Mojo::CookieJar';
use_ok 'Mojo::Cookie::Response';
use_ok 'Mojo::URL';

my $jar = Mojo::CookieJar->new;

# Session cookie
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'foo',
    value  => 'bar'
  )
);
$jar->add(
  Mojo::Cookie::Response->new(
    domain => '.kraih.com',
    path   => '/',
    name   => 'just',
    value  => 'works'
  )
);
my @cookies = $jar->find(Mojo::URL->new('http://kraih.com/foo'));
is $cookies[0]->name,  'foo', 'right name';
is $cookies[0]->value, 'bar', 'right value';
is $cookies[1], undef, 'no second cookie';

# Huge cookie
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'huge',
    value  => 'foo' x 4096
  )
);
@cookies = $jar->find(Mojo::URL->new('http://kraih.com/foo'));
is $cookies[0]->name,  'foo', 'right name';
is $cookies[0]->value, 'bar', 'right value';
is $cookies[1], undef, 'no second cookie';

# Expired cookie
my $expired = Mojo::Cookie::Response->new(
  domain => 'labs.kraih.com',
  path   => '/',
  name   => 'baz',
  value  => '23'
);
$expired->expires(time - 1);
$jar->add($expired);
@cookies = $jar->find(Mojo::URL->new('http://labs.kraih.com/foo'));
is $cookies[0]->name,  'just',  'right name';
is $cookies[0]->value, 'works', 'right value';
is $cookies[1], undef, 'no second cookie';

# Multiple cookies
$jar->add(
  Mojo::Cookie::Response->new(
    domain  => 'labs.kraih.com',
    path    => '/',
    name    => 'baz',
    value   => '23',
    max_age => 60
  )
);
@cookies = $jar->find(Mojo::URL->new('http://labs.kraih.com/foo'));
is $cookies[0]->name,  'baz',   'right name';
is $cookies[0]->value, '23',    'right value';
is $cookies[1]->name,  'just',  'right name';
is $cookies[1]->value, 'works', 'right value';
is $cookies[2], undef, 'no third cookie';

# Multiple cookies with leading dot
$jar->add(
  Mojo::Cookie::Response->new(
    domain => '.kraih.com',
    path   => '/',
    name   => 'this',
    value  => 'that'
  )
);
@cookies = $jar->find(Mojo::URL->new('http://labs.kraih.com/fo'));
is $cookies[0]->name,  'baz',   'right name';
is $cookies[0]->value, '23',    'right value';
is $cookies[1]->name,  'just',  'right name';
is $cookies[1]->value, 'works', 'right value';
is $cookies[2]->name,  'this',  'right name';
is $cookies[2]->value, 'that',  'right value';
is $cookies[3], undef, 'no fourth cookie';

# Replace cookie
$jar = Mojo::CookieJar->new;
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'foo',
    value  => 'bar1'
  )
);
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'foo',
    value  => 'bar2'
  )
);
@cookies = $jar->find(Mojo::URL->new('http://kraih.com/foo'));
is $cookies[0]->value, 'bar2', 'right value';
is $cookies[1], undef, 'no second cookie';

# Non-standard port
$jar = Mojo::CookieJar->new;
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'foo',
    value  => 'bar',
    port   => 88
  )
);
@cookies = $jar->find(Mojo::URL->new('http://kraih.com/foo'));
is $cookies[0], undef, 'no cookie for port 80';
@cookies = $jar->find(Mojo::URL->new('http://kraih.com:88/foo'));
is $cookies[0]->value, 'bar', 'cookie for port 88';
is $cookies[1], undef, 'no second cookie';

# Switch between secure and normal cookies
$jar = Mojo::CookieJar->new;
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'foo',
    value  => 'foo',
    secure => 1
  )
);
@cookies = $jar->find(Mojo::URL->new('https://kraih.com/foo'));
is $cookies[0]->value, 'foo', 'right value';
@cookies = $jar->find(Mojo::URL->new('http://kraih.com/foo'));
is @cookies, 0, 'no insecure cookie';
$jar->add(
  Mojo::Cookie::Response->new(
    domain => 'kraih.com',
    path   => '/foo',
    name   => 'foo',
    value  => 'bar'
  )
);
@cookies = $jar->find(Mojo::URL->new('http://kraih.com/foo'));
is $cookies[0]->value, 'bar', 'right value';
@cookies = $jar->find(Mojo::URL->new('https://kraih.com/foo'));
is $cookies[0]->value, 'bar', 'right value';
is $cookies[1], undef, 'no second cookie';
