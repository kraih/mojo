use Mojo::Base -strict;

BEGIN {
  $ENV{PLACK_ENV}    = undef;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;

use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string;

use Mojo::File qw(path tempdir);

package Mojolicious::Command::my_fake_test_command;

package Mojolicious::Command::my_test_command;
use Mojo::Base 'Mojolicious::Command';

has description => 'See, it works';

package main;

# Make sure @ARGV is not changed
{
  local $ENV{MOJO_MODE};
  local @ARGV = qw(-m production -x whatever);
  require Mojolicious::Commands;
  is $ENV{MOJO_MODE}, 'production', 'right mode';
  is_deeply \@ARGV, [qw(-m production -x whatever)], 'unchanged';
}

# Environment detection
my $commands = Mojolicious::Commands->new;
{
  local $ENV{PLACK_ENV} = 'production';
  is $commands->detect, 'psgi', 'right environment';
}
{
  local $ENV{PATH_INFO} = '/test';
  is $commands->detect, 'cgi', 'right environment';
}
{
  local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
  is $commands->detect, 'cgi', 'right environment';
}
{
  local @ENV{qw(PLACK_ENV PATH_INFO GATEWAY_INTERFACE)};
  is $commands->detect, undef, 'no environment';
}
{
  local $ENV{PLACK_ENV} = 'production';
  is ref Mojolicious::Commands->new->run, 'CODE', 'right reference';
  local $ENV{MOJO_NO_DETECT} = 1;
  isnt ref Mojolicious::Commands->new->run, 'CODE', 'not a CODE reference';
}

# Run command
is ref Mojolicious::Commands->new->run('psgi'), 'CODE', 'right reference';

# Start application
{
  local $ENV{MOJO_APP_LOADER} = 1;
  is ref Mojolicious::Commands->start_app('MojoliciousTest'), 'MojoliciousTest', 'right class';
}

# Start application with command
{
  is ref Mojolicious::Commands->start_app(MojoliciousTest => 'psgi'), 'CODE', 'right reference';
}

# Start application with application specific commands
my $app;
{
  local $ENV{MOJO_APP_LOADER} = 1;
  $app = Mojolicious::Commands->start_app('MojoliciousTest');
}
is $app->start('test_command'),   'works!',   'right result';
is $app->start('test-command'),   'works!',   'right result';
is $app->start('_test2-command'), 'works 2!', 'right result';
{
  is(Mojolicious::Commands->start_app(MojoliciousTest => 'test_command'),   'works!',   'right result');
  is(Mojolicious::Commands->start_app(MojoliciousTest => 'test-command'),   'works!',   'right result');
  is(Mojolicious::Commands->start_app(MojoliciousTest => '_test2-command'), 'works 2!', 'right result');
}

# Application specific help
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  local $ENV{HARNESS_ACTIVE} = 0;
  $app->start;
}
like $buffer, qr/Usage: APPLICATION COMMAND \[OPTIONS\].*_test2-command.*cgi.*test-comm/s, 'right output';

# Commands starting with a dash are not allowed
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  local $ENV{HARNESS_ACTIVE} = 0;
  $app->start('-test2-command');
}
like $buffer, qr/Usage: APPLICATION COMMAND \[OPTIONS\].*_test2-command.*cgi.*test-comm/s, 'right output';

# Do not pick up options for detected environments
{
  local $ENV{MOJO_MODE};
  local $ENV{PLACK_ENV} = 'testing';
  local @ARGV = qw(psgi -m production);
  is ref Mojolicious::Commands->start_app('MojoliciousTest'), 'CODE', 'right reference';
  is $ENV{MOJO_MODE}, undef, 'no mode';
}

# mojo
is_deeply $commands->namespaces, ['Mojolicious::Command::Author', 'Mojolicious::Command'], 'right namespaces';
ok $commands->description, 'has a description';
like $commands->message,   qr/COMMAND/, 'has a message';
like $commands->hint,      qr/help/, 'has a hint';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  local $ENV{HARNESS_ACTIVE} = 0;
  $commands->run;
}
like $buffer, qr/Usage: APPLICATION COMMAND \[OPTIONS\].*daemon.*my-test-command.*version/s, 'right output';
like $buffer,   qr/See, it works/,        'description has been picked up';
unlike $buffer, qr/my-fake-test-command/, 'fake command has been ignored';

# help
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $commands->run('help', 'generate', 'lite-app');
}
like $buffer, qr/Usage: APPLICATION generate lite-app \[OPTIONS\] \[NAME\]/, 'right output';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $commands->run('generate', 'app', '-h');
}
like $buffer, qr/Usage: APPLICATION generate app \[OPTIONS\] \[NAME\]/, 'right output';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $commands->run('generate', 'lite-app', '--help');
}
like $buffer, qr/Usage: APPLICATION generate lite-app \[OPTIONS\] \[NAME\]/, 'right output';

# get
require Mojolicious::Command::get;
my $get = Mojolicious::Command::get->new;
ok $get->description, 'has a description';
like $get->usage, qr/get/, 'has usage information';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $get->run('/');
}
like $buffer, qr/Your Mojo is working!/, 'right output';
my $template = '<p></p><p><%= param "just" %> <%= $c->req->headers->header("X-Test") %></p>';
$get->app->plugins->once(before_dispatch => sub { shift->render(inline => $template) });
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $get->run('-f', 'just=works', '-H', 'X-Test: fine', '/html', 'p', 1, 'text');
}
like $buffer, qr/works fine/, 'right output';
$get->app->plugins->once(before_dispatch => sub { shift->render(json => {works => 'too'}) });
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $get->run('/json', '/works');
}
like $buffer, qr/too/, 'right output';

# cgi
require Mojolicious::Command::cgi;
my $cgi = Mojolicious::Command::cgi->new;
ok $cgi->description, 'has a description';
like $cgi->usage, qr/cgi/, 'has usage information';

# cpanify
require Mojolicious::Command::Author::cpanify;
my $cpanify = Mojolicious::Command::Author::cpanify->new;
ok $cpanify->description, 'has a description';
like $cpanify->usage, qr/cpanify/, 'has usage information';
$cpanify->app->ua->server->app($cpanify->app);
$cpanify->app->ua->unsubscribe('start')->once(
  start => sub {
    my ($ua, $tx) = @_;
    $tx->req->via_proxy(0)->url($ua->server->url->path('/'));
  }
);
$cpanify->app->plugins->once(before_dispatch => sub { shift->render(data => '', status => 200) });
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $cpanify->run('-u', 'sri', '-p', 's3cret', __FILE__);
}
like $buffer, qr/Upload successful!/, 'right output';

# daemon
require Mojolicious::Command::daemon;
my $daemon = Mojolicious::Command::daemon->new;
ok $daemon->description, 'has a description';
like $daemon->usage, qr/daemon/, 'has usage information';

# eval
require Mojolicious::Command::eval;
my $eval = Mojolicious::Command::eval->new;
ok $eval->description, 'has a description';
like $eval->usage, qr/eval/, 'has usage information';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $eval->run('-v', 'app->controller_class');
}
like $buffer, qr/Mojolicious::Controller/, 'right output';
eval { $eval->run('-v', 'die "TEST"') };
like $@, qr/TEST/, 'right output';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $eval->run('-v', 'Mojo::Promise->new->resolve("Zoidberg")');
}
like $buffer, qr/Zoidberg/, 'right output';
eval { $eval->run('-v', 'Mojo::Promise->new->reject("DOOM")') };
like $@, qr/DOOM/, 'right output';

# generate
require Mojolicious::Command::Author::generate;
my $generator = Mojolicious::Command::Author::generate->new;
is_deeply $generator->namespaces, ['Mojolicious::Command::Author::generate'], 'right namespaces';
ok $generator->description, 'has a description';
like $generator->message,   qr/generate/, 'has a message';
like $generator->hint,      qr/help/, 'has a hint';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  local $ENV{HARNESS_ACTIVE} = 0;
  $generator->run;
}
like $buffer, qr/Usage: APPLICATION generate GENERATOR \[OPTIONS\].*lite-app.*plugin/s, 'right output';

# generate app
require Mojolicious::Command::Author::generate::app;
$app = Mojolicious::Command::Author::generate::app->new;
ok $app->description, 'has a description';
like $app->usage, qr/app/, 'has usage information';
my $cwd = path;
my $dir = tempdir;
chdir $dir;
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $app->run;
}
like $buffer, qr/my_app/, 'right output';
ok -e $app->rel_file('my_app/script/my_app'),                     'script exists';
ok -e $app->rel_file('my_app/lib/MyApp.pm'),                      'application class exists';
ok -e $app->rel_file('my_app/lib/MyApp/Controller/Example.pm'),   'controller exists';
ok -e $app->rel_file('my_app/my_app.conf'),                       'config file exists';
ok -e $app->rel_file('my_app/t/basic.t'),                         'test exists';
ok -e $app->rel_file('my_app/public/index.html'),                 'static file exists';
ok -e $app->rel_file('my_app/templates/layouts/default.html.ep'), 'layout exists';
ok -e $app->rel_file('my_app/templates/example/welcome.html.ep'), 'template exists';
chdir $cwd;

# generate lite_app
require Mojolicious::Command::Author::generate::lite_app;
$app = Mojolicious::Command::Author::generate::lite_app->new;
ok $app->description, 'has a description';
like $app->usage, qr/lite-app/, 'has usage information';
$dir = tempdir CLEANUP => 1;
chdir $dir;
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $app->run;
}
like $buffer, qr/myapp\.pl/, 'right output';
ok -e $app->rel_file('myapp.pl'), 'app exists';
chdir $cwd;

# generate makefile
require Mojolicious::Command::Author::generate::makefile;
my $makefile = Mojolicious::Command::Author::generate::makefile->new;
ok $makefile->description, 'has a description';
like $makefile->usage, qr/makefile/, 'has usage information';
$dir = tempdir CLEANUP => 1;
chdir $dir;
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $makefile->run;
}
like $buffer, qr/Makefile\.PL/, 'right output';
ok -e $app->rel_file('Makefile.PL'), 'Makefile.PL exists';
chdir $cwd;

# generate plugin
require Mojolicious::Command::Author::generate::plugin;
my $plugin = Mojolicious::Command::Author::generate::plugin->new;
ok $plugin->description, 'has a description';
like $plugin->usage, qr/plugin/, 'has usage information';
$dir = tempdir CLEANUP => 1;
chdir $dir;
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $plugin->run;
}
like $buffer, qr/MyPlugin\.pm/, 'right output';
ok -e $app->rel_file('Mojolicious-Plugin-MyPlugin/lib/Mojolicious/Plugin/MyPlugin.pm'), 'class exists';
ok -e $app->rel_file('Mojolicious-Plugin-MyPlugin/t/basic.t'),                          'test exists';
ok -e $app->rel_file('Mojolicious-Plugin-MyPlugin/Makefile.PL'),                        'Makefile.PL exists';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $plugin->run('-f', 'MyApp::Ext::Test');
}
like $buffer, qr/Test\.pm/, 'right output';
ok -e $app->rel_file('MyApp-Ext-Test/lib/MyApp/Ext/Test.pm'), 'class exists';
ok -e $app->rel_file('MyApp-Ext-Test/t/basic.t'),             'test exists';
ok -e $app->rel_file('MyApp-Ext-Test/Makefile.PL'),           'Makefile.PL exists';
chdir $cwd;

# inflate
require Mojolicious::Command::Author::inflate;
my $inflate = Mojolicious::Command::Author::inflate->new;
ok $inflate->description, 'has a description';
like $inflate->usage, qr/inflate/, 'has usage information';

# prefork
require Mojolicious::Command::prefork;
my $prefork = Mojolicious::Command::prefork->new;
ok $prefork->description, 'has a description';
like $prefork->usage, qr/prefork/, 'has usage information';

# psgi
require Mojolicious::Command::psgi;
my $psgi = Mojolicious::Command::psgi->new;
ok $psgi->description, 'has a description';
like $psgi->usage, qr/psgi/, 'has usage information';

# routes
require Mojolicious::Command::routes;
my $routes = Mojolicious::Command::routes->new;
ok $routes->description, 'has a description';
like $routes->usage, qr/routes/, 'has usage information';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $routes->run;
}
like $buffer,   qr!/\*whatever!, 'right output';
unlike $buffer, qr!/\(\.\+\)\?!, 'not verbose';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $routes->run('-v');
}
like $buffer, qr!/\*whatever!, 'right output';
like $buffer, qr!/\(\.\+\)\?!, 'verbose';

# version
require Mojolicious::Command::version;
my $version = Mojolicious::Command::version->new;
ok $version->description, 'has a description';
like $version->usage, qr/version/, 'has usage information';
$version->app->ua->server->app($version->app);
$version->app->ua->once(
  start => sub {
    my ($ua, $tx) = @_;
    $tx->req->via_proxy(0)->url($ua->server->url->path('/'));
  }
);
$version->app->plugins->once(before_dispatch => sub { shift->render(json => {version => 1000}) });
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $version->run;
}
like $buffer, qr/Perl/,                                               'right output';
like $buffer, qr/You might want to update your Mojolicious to 1000!/, 'right output';

# Hooks
$app = Mojolicious->new;
$app->hook(
  before_command => sub {
    my ($command, $args) = @_;
    return unless $command->isa('Mojolicious::Command::eval');
    $command->app->config->{test} = 'works!';
    unshift @$args, '-v';
  }
);
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $app->start('eval', 'app->config->{test}');
}
like $buffer, qr/works!/, 'right output';

done_testing();
