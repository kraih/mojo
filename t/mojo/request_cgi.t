use Mojo::Base -strict;

use Test::More tests => 188;

# "Aren't we forgetting the true meaning of Christmas?
#  You know, the birth of Santa."
use Mojo::Message::Request;

# Parse Lighttpd like CGI environment variables and a body
my $req  = Mojo::Message::Request->new;
my $body = 0;
$req->content->on(body => sub { $body++ });
$req->parse(
  HTTP_CONTENT_LENGTH => 11,
  HTTP_EXPECT         => '100-continue',
  PATH_INFO           => '/test/index.cgi/foo/bar',
  QUERY_STRING        => 'lalala=23&bar=baz',
  REQUEST_METHOD      => 'POST',
  SCRIPT_NAME         => '/test/index.cgi',
  HTTP_HOST           => 'localhost:8080',
  SERVER_PROTOCOL     => 'HTTP/1.0'
);
is $body, 1, 'body event has been emitted once';
$req->parse('Hello ');
is $body, 1, 'body event has been emitted once';
$req->parse('World');
is $body, 1, 'body event has been emitted once';
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->headers->expect, '100-continue', 'right "Expect" value';
is $req->url->path,       'foo/bar',      'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->url->base->host, 'localhost',        'right base host';
is $req->url->base->port, 8080,               'right base port';
is $req->url->query, 'lalala=23&bar=baz', 'right query';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'Hello World', 'right content';
is $req->url->to_abs->to_string,
  'http://localhost:8080/test/index.cgi/foo/bar?lalala=23&bar=baz',
  'right absolute URL';

# Parse Lighttpd like CGI environment variables and a body
# (behind reverse proxy)
$req = Mojo::Message::Request->new;
$req->parse(
  HTTP_CONTENT_LENGTH  => 11,
  HTTP_EXPECT          => '100-continue',
  HTTP_X_FORWARDED_FOR => '127.0.0.1',
  PATH_INFO            => '/test/index.cgi/foo/bar',
  QUERY_STRING         => 'lalala=23&bar=baz',
  REQUEST_METHOD       => 'POST',
  SCRIPT_NAME          => '/test/index.cgi',
  HTTP_HOST            => 'mojolicio.us',
  SERVER_PROTOCOL      => 'HTTP/1.0'
);
$req->parse('Hello World');
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->headers->expect, '100-continue', 'right "Expect" value';
is $req->url->path,       'foo/bar',      'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->url->base->host, 'mojolicio.us',     'right base host';
is $req->url->base->port, '',                 'right base port';
is $req->url->query, 'lalala=23&bar=baz', 'right query';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'Hello World', 'right content';
is $req->url->to_abs->to_string,
  'http://mojolicio.us/test/index.cgi/foo/bar?lalala=23&bar=baz',
  'right absolute URL';

# Parse Apache like CGI environment variables and a body
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH  => 11,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded',
  HTTP_EXPECT     => '100-continue',
  PATH_INFO       => '/test/index.cgi/foo/bar',
  QUERY_STRING    => 'lalala=23&bar=baz',
  REQUEST_METHOD  => 'POST',
  SCRIPT_NAME     => '/test/index.cgi',
  HTTP_HOST       => 'localhost:8080',
  SERVER_PROTOCOL => 'HTTP/1.0'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->headers->expect, '100-continue', 'right "Expect" value';
is $req->url->path,       'foo/bar',      'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->url->base->host, 'localhost',        'right base host';
is $req->url->base->port, 8080,               'right base port';
is $req->url->query, 'lalala=23&bar=baz', 'right query';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right value';
is $req->url->to_abs->to_string,
  'http://localhost:8080/test/index.cgi/foo/bar?lalala=23&bar=baz',
  'right absolute URL';

# Parse Apache like CGI environment variables with basic authentication
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH           => 11,
  HTTP_Authorization       => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==',
  HTTP_Proxy_Authorization => 'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==',
  CONTENT_TYPE             => 'application/x-www-form-urlencoded',
  HTTP_EXPECT              => '100-continue',
  PATH_INFO                => '/test/index.cgi/foo/bar',
  QUERY_STRING             => 'lalala=23&bar=baz',
  REQUEST_METHOD           => 'POST',
  SCRIPT_NAME              => '/test/index.cgi',
  HTTP_HOST                => 'localhost:8080',
  SERVER_PROTOCOL          => 'HTTP/1.0'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->headers->expect, '100-continue', 'right "Expect" value';
is $req->url->path,       'foo/bar',      'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->url->base->host, 'localhost',        'right base host';
is $req->url->base->port, 8080,               'right base port';
is $req->url->query, 'lalala=23&bar=baz', 'right query';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right value';
is $req->url->to_abs->to_string, 'http://Aladdin:open%20sesame@localhost:8080'
  . '/test/index.cgi/foo/bar?lalala=23&bar=baz', 'right absolute URL';
is $req->url->base,
  'http://Aladdin:open%20sesame@localhost:8080/test/index.cgi/',
  'right base URL';
is $req->url->base->userinfo, 'Aladdin:open sesame', 'right userinfo';
is $req->url, 'foo/bar?lalala=23&bar=baz', 'right URL';
is $req->proxy->userinfo, 'Aladdin:open sesame', 'right proxy userinfo';

# Parse Apache 2.2 (win32) like CGI environment variables and a body
$req = Mojo::Message::Request->new;
my $finished;
my $progress = 0;
$req->on(finish => sub { $finished = shift->is_finished });
$req->on(progress => sub { $progress++ });
ok !$finished, 'not finished';
ok !$progress, 'no progress';
is $req->content->progress, 0, 'right progress';
$req->parse(
  CONTENT_LENGTH  => 87,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded; charset=UTF-8',
  PATH_INFO       => '',
  QUERY_STRING    => '',
  REQUEST_METHOD  => 'POST',
  SCRIPT_NAME     => '/index.pl',
  HTTP_HOST       => 'test1',
  SERVER_PROTOCOL => 'HTTP/1.1'
);
ok !$finished, 'not finished';
ok $progress, 'made progress';
$progress = 0;
is $req->content->progress, 0, 'right progress';
$req->parse('request=&ajax=true&login=test&password=111&');
ok !$finished, 'not finished';
ok $progress, 'made progress';
$progress = 0;
is $req->content->progress, 43, 'right progress';
$req->parse('edition=db6d8b30-16df-4ecd-be2f-c8194f94e1f4');
ok $finished, 'finished';
ok $progress, 'made progress';
is $req->content->progress, 87, 'right progress';
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->url->path, '', 'right path';
is $req->url->base->path, '/index.pl/', 'right base path';
is $req->url->base->host, 'test1',      'right base host';
is $req->url->base->port, '',           'right base port';
ok !$req->url->query->to_string, 'no query';
is $req->version, '1.1', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'request=&ajax=true&login=test&password=111&'
  . 'edition=db6d8b30-16df-4ecd-be2f-c8194f94e1f4', 'right content';
is $req->param('ajax'),     'true', 'right value';
is $req->param('login'),    'test', 'right value';
is $req->param('password'), '111',  'right value';
is $req->param('edition'), 'db6d8b30-16df-4ecd-be2f-c8194f94e1f4',
  'right value';
is $req->url->to_abs->to_string, 'http://test1/index.pl',
  'right absolute URL';

# Parse Apache 2.2 (win32) like CGI environment variables and a body
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH  => 87,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded; charset=UTF-8',
  PATH_INFO       => '',
  QUERY_STRING    => '',
  REQUEST_METHOD  => 'POST',
  SCRIPT_NAME     => '/index.pl',
  HTTP_HOST       => 'test1',
  SERVER_PROTOCOL => 'HTTP/1.1'
);
$req->parse('request=&ajax=true&login=test&password=111&');
$req->parse('edition=db6d8b30-16df-4ecd-be2f-c8194f94e1f4');
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->url->path, '', 'right path';
is $req->url->base->path, '/index.pl/', 'right base path';
is $req->url->base->host, 'test1',      'right base host';
is $req->url->base->port, '',           'right base port';
ok !$req->url->query->to_string, 'no query';
is $req->version, '1.1', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'request=&ajax=true&login=test&password=111&'
  . 'edition=db6d8b30-16df-4ecd-be2f-c8194f94e1f4', 'right content';
is $req->param('ajax'),     'true', 'right value';
is $req->param('login'),    'test', 'right value';
is $req->param('password'), '111',  'right value';
is $req->param('edition'), 'db6d8b30-16df-4ecd-be2f-c8194f94e1f4',
  'right value';
is $req->url->to_abs->to_string, 'http://test1/index.pl',
  'right absolute URL';

# Parse Apache 2.2.14 like CGI environment variables and a body (root)
$req = Mojo::Message::Request->new;
$req->parse(
  SCRIPT_NAME       => '/upload',
  SERVER_NAME       => '127.0.0.1',
  SERVER_ADMIN      => '[no address given]',
  PATH_INFO         => '/upload',
  HTTP_CONNECTION   => 'Keep-Alive',
  REQUEST_METHOD    => 'POST',
  CONTENT_LENGTH    => '11',
  SCRIPT_FILENAME   => '/tmp/SnLu1cQ3t2/test.fcgi',
  SERVER_SOFTWARE   => 'Apache/2.2.14 (Unix) mod_fastcgi/2.4.2',
  QUERY_STRING      => '',
  REMOTE_PORT       => '58232',
  HTTP_USER_AGENT   => 'Mojolicious (Perl)',
  SERVER_PORT       => '13028',
  SERVER_SIGNATURE  => '',
  REMOTE_ADDR       => '127.0.0.1',
  CONTENT_TYPE      => 'application/x-www-form-urlencoded; charset=UTF-8',
  SERVER_PROTOCOL   => 'HTTP/1.1',
  REQUEST_URI       => '/upload',
  GATEWAY_INTERFACE => 'CGI/1.1',
  SERVER_ADDR       => '127.0.0.1',
  DOCUMENT_ROOT     => '/tmp/SnLu1cQ3t2',
  PATH_TRANSLATED   => '/tmp/test.fcgi/upload',
  HTTP_HOST         => '127.0.0.1:13028'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->url->base->host, '127.0.0.1', 'right base host';
is $req->url->base->port, 13028,       'right base port';
is $req->url->path, '', 'right path';
is $req->url->base->path, '/upload/', 'right base path';
is $req->version, '1.1', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
ok !$req->is_secure, 'not secure';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right parameters';
is $req->url->to_abs->to_string, 'http://127.0.0.1:13028/upload',
  'right absolute URL';

# Parse Apache 2.2.11 like CGI environment variables and a body (HTTPS)
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH  => 11,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded',
  PATH_INFO       => '/foo/bar',
  QUERY_STRING    => '',
  REQUEST_METHOD  => 'GET',
  SCRIPT_NAME     => '/test/index.cgi',
  HTTP_HOST       => 'localhost',
  HTTPS           => 'on',
  SERVER_PROTOCOL => 'HTTP/1.0'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'GET', 'right method';
is $req->url->base->host, 'localhost', 'right base host';
is $req->url->path, 'foo/bar', 'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
ok $req->is_secure, 'is secure';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right parameters';
is $req->url->to_abs->to_string, 'https://localhost/test/index.cgi/foo/bar',
  'right absolute URL';

# Parse Apache 2.2.11 like CGI environment variables and a body
# (trailing slash)
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH  => 11,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded',
  PATH_INFO       => '/foo/bar/',
  QUERY_STRING    => '',
  REQUEST_METHOD  => 'GET',
  SCRIPT_NAME     => '/test/index.cgi',
  HTTP_HOST       => 'localhost',
  SERVER_PROTOCOL => 'HTTP/1.0'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'GET', 'right method';
is $req->url->base->host, 'localhost', 'right base host';
is $req->url->path, 'foo/bar/', 'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right parameters';
is $req->url->to_abs->to_string, 'http://localhost/test/index.cgi/foo/bar/',
  'right absolute URL';

# Parse Apache 2.2.11 like CGI environment variables and a body
# (no SCRIPT_NAME)
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH  => 11,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded',
  PATH_INFO       => '/foo/bar',
  QUERY_STRING    => '',
  REQUEST_METHOD  => 'GET',
  HTTP_HOST       => 'localhost',
  SERVER_PROTOCOL => 'HTTP/1.0'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'GET', 'right method';
is $req->url->base->host, 'localhost', 'right base host';
is $req->url->path, '/foo/bar', 'right path';
is $req->url->base->path, '', 'right base path';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right parameters';
is $req->url->to_abs->to_string, 'http://localhost/foo/bar',
  'right absolute URL';

# Parse Apache 2.2.11 like CGI environment variables and a body
# (no PATH_INFO)
$req = Mojo::Message::Request->new;
$req->parse(
  CONTENT_LENGTH  => 11,
  CONTENT_TYPE    => 'application/x-www-form-urlencoded',
  QUERY_STRING    => '',
  REQUEST_METHOD  => 'GET',
  SCRIPT_NAME     => '/test/index.cgi',
  HTTP_HOST       => 'localhost',
  SERVER_PROTOCOL => 'HTTP/1.0'
);
$req->parse('hello=world');
ok $req->is_finished, 'request is finished';
is $req->method, 'GET', 'right method';
is $req->url->base->host, 'localhost', 'right base host';
is $req->url->path, '', 'right path';
is $req->url->base->path, '/test/index.cgi/', 'right base path';
is $req->version, '1.0', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->body, 'hello=world', 'right content';
is_deeply $req->param('hello'), 'world', 'right parameters';
is $req->url->to_abs->to_string, 'http://localhost/test/index.cgi',
  'right absolute URL';

# Parse Apache 2.2.9 like CGI environment variables (root without PATH_INFO)
$req = Mojo::Message::Request->new;
$req->parse(
  SCRIPT_NAME     => '/cgi-bin/myapp/myapp.pl',
  HTTP_CONNECTION => 'keep-alive',
  HTTP_HOST       => 'getmyapp.org',
  REQUEST_METHOD  => 'GET',
  QUERY_STRING    => '',
  REQUEST_URI     => '/cgi-bin/myapp/myapp.pl',
  SERVER_PROTOCOL => 'HTTP/1.1',
);
ok $req->is_finished, 'request is finished';
is $req->method, 'GET', 'right method';
is $req->url->base->host, 'getmyapp.org', 'right base host';
is $req->url->path, '', 'right path';
is $req->url->base->path, '/cgi-bin/myapp/myapp.pl/', 'right base path';
is $req->version, '1.1', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->url->to_abs->to_string,
  'http://getmyapp.org/cgi-bin/myapp/myapp.pl',
  'right absolute URL';

# Parse Apache mod_fastcgi like CGI environment variables
# (multipart file upload)
$req = Mojo::Message::Request->new;
is $req->content->progress, 0, 'right progress';
$req->parse(
  SCRIPT_NAME      => '',
  SERVER_NAME      => '127.0.0.1',
  SERVER_ADMIN     => '[no address given]',
  PATH_INFO        => '/upload',
  HTTP_CONNECTION  => 'Keep-Alive',
  REQUEST_METHOD   => 'POST',
  CONTENT_LENGTH   => '135',
  SCRIPT_FILENAME  => '/tmp/SnLu1cQ3t2/test.fcgi',
  SERVER_SOFTWARE  => 'Apache/2.2.14 (Unix) mod_fastcgi/2.4.2',
  QUERY_STRING     => '',
  REMOTE_PORT      => '58232',
  HTTP_USER_AGENT  => 'Mojolicious (Perl)',
  SERVER_PORT      => '13028',
  SERVER_SIGNATURE => '',
  REMOTE_ADDR      => '127.0.0.1',
  CONTENT_TYPE     => 'multipart/form-data; boundary=8jXGX',
  SERVER_PROTOCOL  => 'HTTP/1.1',
  PATH => '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin',
  REQUEST_URI       => '/upload',
  GATEWAY_INTERFACE => 'CGI/1.1',
  SERVER_ADDR       => '127.0.0.1',
  DOCUMENT_ROOT     => '/tmp/SnLu1cQ3t2',
  PATH_TRANSLATED   => '/tmp/test.fcgi/upload',
  HTTP_HOST         => '127.0.0.1:13028'
);
is $req->content->progress, 0, 'right progress';
$req->parse("--8jXGX\x0d\x0a");
is $req->content->progress, 9, 'right progress';
$req->parse(
  "Content-Disposition: form-data; name=\"file\"; filename=\"file\"\x0d\x0a"
    . "Content-Type: application/octet-stream\x0d\x0a\x0d\x0a");
is $req->content->progress, 113, 'right progress';
$req->parse('11023456789');
is $req->content->progress, 124, 'right progress';
$req->parse("\x0d\x0a--8jXGX--");
is $req->content->progress, 135, 'right progress';
ok $req->is_finished, 'request is finished';
is $req->method, 'POST', 'right method';
is $req->url->base->host, '127.0.0.1', 'right base host';
is $req->url->path, '/upload', 'right path';
is $req->url->base->path, '', 'no base path';
is $req->version, '1.1', 'right version';
ok $req->at_least_version('1.0'), 'at least version 1.0';
ok !$req->at_least_version('1.2'), 'not version 1.2';
is $req->url->to_abs->to_string,
  'http://127.0.0.1:13028/upload',
  'right absolute URL';
my $file = $req->upload('file');
is $file->slurp, '11023456789', 'right uploaded content';
