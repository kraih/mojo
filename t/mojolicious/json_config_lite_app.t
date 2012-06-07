use Mojo::Base -strict;

use utf8;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More tests => 26;

# "Oh, I always feared he might run off like this.
#  Why, why, why didn't I break his legs?"
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Mojolicious::Lite;
use Test::Mojo;

# Default
app->config(it => 'works');
is_deeply app->config, {it => 'works'}, 'right value';

# Load plugins
my $config
  = plugin j_s_o_n_config => {default => {foo => 'baz', hello => 'there'}};
plugin JSONConfig => {file =>
    abs_path(catfile(dirname(__FILE__), 'json_config_lite_app_abs.json'))};
is $config->{foo},          'bar',            'right value';
is $config->{hello},        'there',          'right value';
is $config->{utf},          'утф',         'right value';
is $config->{absolute},     'works too!',     'right value';
is $config->{absolute_dev}, 'dev works too!', 'right value';
is app->config->{foo},          'bar',            'right value';
is app->config->{hello},        'there',          'right value';
is app->config->{utf},          'утф',         'right value';
is app->config->{absolute},     'works too!',     'right value';
is app->config->{absolute_dev}, 'dev works too!', 'right value';
is app->config('foo'),          'bar',            'right value';
is app->config('hello'),        'there',          'right value';
is app->config('utf'),          'утф',         'right value';
is app->config('absolute'),     'works too!',     'right value';
is app->config('absolute_dev'), 'dev works too!', 'right value';
is app->config('it'),           'works',          'right value';

# GET /
get '/' => 'index';

my $t = Test::Mojo->new;

# GET /
$t->get_ok('/')->status_is(200)->content_is("barbarbar\n");

# No config file, default only
$config
  = plugin JSONConfig => {file => 'nonexistent', default => {foo => 'qux'}};
is $config->{foo}, 'qux', 'right value';
is app->config->{foo}, 'qux', 'right value';
is app->config('foo'), 'qux',   'right value';
is app->config('it'),  'works', 'right value';

# No config file, no default
{
  ok !(eval { plugin JSONConfig => {file => 'nonexistent'} }),
    'no config file';
  local $ENV{MOJO_CONFIG} = 'nonexistent';
  ok !(eval { plugin 'JSONConfig' }), 'no config file';
}

__DATA__
@@ index.html.ep
<%= $config->{foo} %><%= config->{foo} %><%= config 'foo' %>
