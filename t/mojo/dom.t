#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use Test::More tests => 411;

# "Homer gave me a kidney: it wasn't his, I didn't need it,
#  and it came postage due- but I appreciated the gesture!"
use_ok 'Mojo::DOM';
use_ok 'ojo';

use Mojo::Util 'encode';

my $dom = Mojo::DOM->new;

# ojo
is x('<div>Hello ♥!</div>')->at('div')->text, 'Hello ♥!', 'right text';

# Simple (basics)
$dom->parse('<div><div id="a">A</div><div id="b">B</div></div>');
is $dom->at('#b')->text, 'B', 'right text';
my @div;
$dom->find('div[id]')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A B/], 'found all div elements with id';
@div = ();
$dom->find('div[id]')->each(sub { push @div, $_->text });
is_deeply \@div, [qw/A B/], 'found all div elements with id';
@div = ();
$dom->find('div[id]')->until(sub { push @div, shift->text; @div == 1 });
is_deeply \@div, [qw/A/], 'found first div elements with id';
@div = ();
$dom->find('div[id]')->until(sub { pop == 1 && push @div, $_->text });
is_deeply \@div, [qw/A/], 'found first div elements with id';
@div = ();
$dom->find('div[id]')->while(sub { push @div, shift->text; @div < 1 });
is_deeply \@div, [qw/A/], 'found first div elements with id';
@div = ();
$dom->find('div[id]')->while(sub { pop() < 2 && push @div, $_->text });
is_deeply \@div, [qw/A/], 'found first div elements with id';

# Simple nesting (tree structure)
$dom->parse(<<EOF);
<foo><bar a="b&lt;c">ju<baz a23>s<bazz />t</bar>works</foo>
EOF
is $dom->tree->[0], 'root', 'right element';
is $dom->tree->[1]->[0], 'tag', 'right element';
is $dom->tree->[1]->[1], 'foo', 'right tag';
is_deeply $dom->tree->[1]->[2], {}, 'empty attributes';
is $dom->tree->[1]->[3], $dom->tree, 'right parent';
is $dom->tree->[1]->[4]->[0], 'tag', 'right element';
is $dom->tree->[1]->[4]->[1], 'bar', 'right tag';
is_deeply $dom->tree->[1]->[4]->[2], {a => 'b<c'}, 'right attributes';
is $dom->tree->[1]->[4]->[3], $dom->tree->[1], 'right parent';
is $dom->tree->[1]->[4]->[4]->[0], 'text', 'right element';
is $dom->tree->[1]->[4]->[4]->[1], 'ju',   'right text';
is $dom->tree->[1]->[4]->[5]->[0], 'tag',  'right element';
is $dom->tree->[1]->[4]->[5]->[1], 'baz',  'right tag';
is_deeply $dom->tree->[1]->[4]->[5]->[2], {a23 => undef}, 'right attributes';
is $dom->tree->[1]->[4]->[5]->[3], $dom->tree->[1]->[4], 'right parent';
is $dom->tree->[1]->[4]->[6]->[0], 'text', 'right element';
is $dom->tree->[1]->[4]->[6]->[1], 's',    'right text';
is $dom->tree->[1]->[4]->[7]->[0], 'tag',  'right element';
is $dom->tree->[1]->[4]->[7]->[1], 'bazz', 'right tag';
is_deeply $dom->tree->[1]->[4]->[7]->[2], {}, 'empty attributes';
is $dom->tree->[1]->[4]->[7]->[3], $dom->tree->[1]->[4], 'right parent';
is $dom->tree->[1]->[4]->[8]->[0], 'text', 'right element';
is $dom->tree->[1]->[4]->[8]->[1], 't',    'right text';
is $dom->tree->[1]->[5]->[0], 'text',  'right element';
is $dom->tree->[1]->[5]->[1], 'works', 'right text';
is "$dom", <<EOF, 'stringified right';
<foo><bar a="b&lt;c">ju<baz a23 />s<bazz />t</bar>works</foo>
EOF

# A bit of everything (basic navigation)
$dom->parse(<<EOF);
<!doctype foo>
<foo bar="ba&lt;z">
  test
  <simple class="working">easy</simple>
  <test foo="bar" id="test" />
  <!-- lala -->
  works well
  <![CDATA[ yada yada]]>
  <?boom lalalala ?>
  <a little bit broken>
  < very broken
  <br />
  more text
</foo>
EOF
is $dom->tree->[1]->[0], 'doctype', 'right element';
is $dom->tree->[1]->[1], ' foo',    'right doctype';
is "$dom", <<EOF, 'stringified right';
<!DOCTYPE foo>
<foo bar="ba&lt;z">
  test
  <simple class="working">easy</simple>
  <test foo="bar" id="test" />
  <!-- lala -->
  works well
  <![CDATA[ yada yada]]>
  <?boom lalalala ?>
  <a bit broken little />
  <very <br broken />
  more text
</foo>
EOF
my $simple = $dom->at('foo simple.working[class^="wor"]');
like $simple->parent->all_text,
  qr/test\s+easy\s+works\s+well\s+yada\s+yada\s+more\s+text/;
is $simple->type, 'simple', 'right type';
is $simple->attrs('class'), 'working', 'right class attribute';
is $simple->text, 'easy', 'right text';
is $simple->parent->type, 'foo', 'right parent type';
is $simple->parent->attrs->{bar}, 'ba<z', 'right parent attribute';
is $simple->parent->children->[1]->type, 'test', 'right sibling';
is $simple->to_xml, '<simple class="working">easy</simple>',
  'stringified right';
$simple->parent->attrs(bar => 'baz')->attrs({this => 'works', too => 'yea'});
is $simple->parent->attrs('bar'),  'baz',   'right parent attribute';
is $simple->parent->attrs('this'), 'works', 'right parent attribute';
is $simple->parent->attrs('too'),  'yea',   'right parent attribute';
is $dom->at('test#test')->type,         'test',   'right type';
is $dom->at('[class$="ing"]')->type,    'simple', 'right type';
is $dom->at('[class="working"]')->type, 'simple', 'right type';
is $dom->at('[class$=ing]')->type,      'simple', 'right type';
is $dom->at('[class=working]')->type,   'simple', 'right type';

# Deep nesting (parent combinator)
$dom->parse(<<EOF);
<html>
  <head>
    <title>Foo</title>
  </head>
  <body>
    <div id="container">
      <div id="header">
        <div id="logo">Hello World</div>
        <div id="buttons">
          <p id="foo">Foo</p>
        </div>
      </div>
      <form>
        <div id="buttons">
          <p id="bar">Bar</p>
        </div>
      </form>
      <div id="content">More stuff</div>
    </div>
  </body>
</html>
EOF
my $p = $dom->find('body > #container > div p[id]');
is $p->[0]->attrs('id'), 'foo', 'right id attribute';
is $p->[1], undef, 'no second result';
my @p;
@div = ();
$dom->find('div')->each(sub { push @div, $_->attrs('id') })->find('p')
  ->each(sub { push @p, $_->attrs('id') });
is_deeply \@p, [qw/foo bar/], 'found all p elements';
my $ids = [qw/container header logo buttons buttons content/];
is_deeply \@div, $ids, 'found all div elements';

# Script tag
$dom->parse(<<EOF);
<script type="text/javascript" charset="utf-8">alert('lalala');</script>
EOF
is $dom->at('script')->text, "alert('lalala');", 'right script content';

# HTML5 (unquoted values)
$dom->parse(qq/<div id = test foo ="bar" class=tset>works<\/div>/);
is $dom->at('#test')->text,       'works', 'right text';
is $dom->at('div')->text,         'works', 'right text';
is $dom->at('[foo="bar"]')->text, 'works', 'right text';
is $dom->at('[foo="ba"]'), undef, 'no result';
is $dom->at('[foo=bar]')->text, 'works', 'right text';
is $dom->at('[foo=ba]'), undef, 'no result';
is $dom->at('.tset')->text, 'works', 'right text';

# HTML1 (single quotes, uppercase tags and whitespace in attributes)
$dom->parse(qq/<DIV id = 'test' foo ='bar' class= "tset">works<\/DIV>/);
is $dom->at('#test')->text,       'works', 'right text';
is $dom->at('div')->text,         'works', 'right text';
is $dom->at('[foo="bar"]')->text, 'works', 'right text';
is $dom->at('[foo="ba"]'), undef, 'no result';
is $dom->at('[foo=bar]')->text, 'works', 'right text';
is $dom->at('[foo=ba]'), undef, 'no result';
is $dom->at('.tset')->text, 'works', 'right text';

# Already decoded unicode snowman and quotes in selector
$dom->parse('<div id="sno&quot;wman">☃</div>');
is $dom->at('[id="sno\"wman"]')->text, '☃', 'right text';

# Unicode and escaped selectors
my $unicode =
  qq/<html><div id="☃x">Snowman<\/div><div class="x ♥">Heart<\/div><\/html>/;
encode 'UTF-8', $unicode;
$dom->charset('UTF-8');
$dom->parse($unicode);
is $dom->at("#\\\n\\002603x")->text,                  'Snowman', 'right text';
is $dom->at('#\\2603 x')->text,                       'Snowman', 'right text';
is $dom->at("#\\\n\\2603 x")->text,                   'Snowman', 'right text';
is $dom->at(qq/[id="\\\n\\2603 x"]/)->text,           'Snowman', 'right text';
is $dom->at(qq/[id="\\\n\\002603x"]/)->text,          'Snowman', 'right text';
is $dom->at(qq/[id="\\\\2603 x"]/)->text,             'Snowman', 'right text';
is $dom->at("html #\\\n\\002603x")->text,             'Snowman', 'right text';
is $dom->at('html #\\2603 x')->text,                  'Snowman', 'right text';
is $dom->at("html #\\\n\\2603 x")->text,              'Snowman', 'right text';
is $dom->at(qq/html [id="\\\n\\2603 x"]/)->text,      'Snowman', 'right text';
is $dom->at(qq/html [id="\\\n\\002603x"]/)->text,     'Snowman', 'right text';
is $dom->at(qq/html [id="\\\\2603 x"]/)->text,        'Snowman', 'right text';
is $dom->at('#☃x')->text,                           'Snowman', 'right text';
is $dom->at('div#☃x')->text,                        'Snowman', 'right text';
is $dom->at('html div#☃x')->text,                   'Snowman', 'right text';
is $dom->at('[id^="☃"]')->text,                     'Snowman', 'right text';
is $dom->at('div[id^="☃"]')->text,                  'Snowman', 'right text';
is $dom->at('html div[id^="☃"]')->text,             'Snowman', 'right text';
is $dom->at('html > div[id^="☃"]')->text,           'Snowman', 'right text';
is $dom->at('[id^=☃]')->text,                       'Snowman', 'right text';
is $dom->at('div[id^=☃]')->text,                    'Snowman', 'right text';
is $dom->at('html div[id^=☃]')->text,               'Snowman', 'right text';
is $dom->at('html > div[id^=☃]')->text,             'Snowman', 'right text';
is $dom->at(".\\\n\\002665")->text,                   'Heart',   'right text';
is $dom->at('.\\2665')->text,                         'Heart',   'right text';
is $dom->at("html .\\\n\\002665")->text,              'Heart',   'right text';
is $dom->at('html .\\2665')->text,                    'Heart',   'right text';
is $dom->at(qq/html [class\$="\\\n\\002665"]/)->text, 'Heart',   'right text';
is $dom->at(qq/html [class\$="\\2665"]/)->text,       'Heart',   'right text';
is $dom->at(qq/[class\$="\\\n\\002665"]/)->text,      'Heart',   'right text';
is $dom->at(qq/[class\$="\\2665"]/)->text,            'Heart',   'right text';
is $dom->at('.x')->text,                              'Heart',   'right text';
is $dom->at('html .x')->text,                         'Heart',   'right text';
is $dom->at('.♥')->text,                            'Heart',   'right text';
is $dom->at('html .♥')->text,                       'Heart',   'right text';
is $dom->at('div.♥')->text,                         'Heart',   'right text';
is $dom->at('html div.♥')->text,                    'Heart',   'right text';
is $dom->at('[class$="♥"]')->text,                  'Heart',   'right text';
is $dom->at('div[class$="♥"]')->text,               'Heart',   'right text';
is $dom->at('html div[class$="♥"]')->text,          'Heart',   'right text';
is $dom->at('html > div[class$="♥"]')->text,        'Heart',   'right text';
is $dom->at('[class$=♥]')->text,                    'Heart',   'right text';
is $dom->at('div[class$=♥]')->text,                 'Heart',   'right text';
is $dom->at('html div[class$=♥]')->text,            'Heart',   'right text';
is $dom->at('html > div[class$=♥]')->text,          'Heart',   'right text';
is $dom->at('[class~="♥"]')->text,                  'Heart',   'right text';
is $dom->at('div[class~="♥"]')->text,               'Heart',   'right text';
is $dom->at('html div[class~="♥"]')->text,          'Heart',   'right text';
is $dom->at('html > div[class~="♥"]')->text,        'Heart',   'right text';
is $dom->at('[class~=♥]')->text,                    'Heart',   'right text';
is $dom->at('div[class~=♥]')->text,                 'Heart',   'right text';
is $dom->at('html div[class~=♥]')->text,            'Heart',   'right text';
is $dom->at('html > div[class~=♥]')->text,          'Heart',   'right text';
is $dom->at('[class~="x"]')->text,                    'Heart',   'right text';
is $dom->at('div[class~="x"]')->text,                 'Heart',   'right text';
is $dom->at('html div[class~="x"]')->text,            'Heart',   'right text';
is $dom->at('html > div[class~="x"]')->text,          'Heart',   'right text';
is $dom->at('[class~=x]')->text,                      'Heart',   'right text';
is $dom->at('div[class~=x]')->text,                   'Heart',   'right text';
is $dom->at('html div[class~=x]')->text,              'Heart',   'right text';
is $dom->at('html > div[class~=x]')->text,            'Heart',   'right text';
$dom->charset(undef);

# Looks remotely like HTML
$dom->parse('<!DOCTYPE H "-/W/D HT 4/E">☃<title class=test>♥</title>☃');
is $dom->at('title')->text, '♥', 'right text';
is $dom->at('*')->text,     '♥', 'right text';
is $dom->at('.test')->text, '♥', 'right text';

# Replace elements
$dom->parse('<div>foo<p>lalala</p>bar</div>');
$dom->at('p')->replace('<foo>bar</foo>');
is "$dom", '<div>foo<foo>bar</foo>bar</div>', 'right text';
$dom->at('foo')->replace(Mojo::DOM->new->parse('text'));
is "$dom", '<div>footextbar</div>', 'right text';
$dom->parse('<div>foo</div><div>bar</div>');
$dom->find('div')->each(sub { shift->replace('<p>test</p>') });
is "$dom", '<p>test</p><p>test</p>', 'right text';
$dom->parse('<div>foo<p>lalala</p>bar</div>');
$dom->replace('♥');
is "$dom", '♥', 'right text';
$dom->replace('<div>foo<p>lalala</p>bar</div>');
is "$dom", '<div>foo<p>lalala</p>bar</div>', 'right text';
$dom->replace('');
is "$dom", '', 'right text';
$dom->replace('<div>foo<p>lalala</p>bar</div>');
is "$dom", '<div>foo<p>lalala</p>bar</div>', 'right text';
$dom->find('p')->each(sub { shift->replace('') });
is "$dom", '<div>foobar</div>', 'right text';
$dom->parse('<div>♥</div>');
$dom->at('div')->replace_inner('☃');
is "$dom", '<div>☃</div>', 'right text';
$dom->parse('<div>♥</div>');
$dom->at('div')->replace_inner("\x{2603}");
is "$dom", '<div>☃</div>', 'right text';

# Replace element content
$dom->parse('<div>foo<p>lalala</p>bar</div>');
$dom->at('p')->replace_inner('bar');
is "$dom", '<div>foo<p>bar</p>bar</div>', 'right text';
$dom->at('p')->replace_inner(Mojo::DOM->new->parse('text'));
is "$dom", '<div>foo<p>text</p>bar</div>', 'right text';
$dom->parse('<div>foo</div><div>bar</div>');
$dom->find('div')->each(sub { shift->replace_inner('<p>test</p>') });
is "$dom", '<div><p>test</p></div><div><p>test</p></div>', 'right text';
$dom->find('p')->each(sub { shift->replace_inner('') });
is "$dom", '<div><p /></div><div><p /></div>', 'right text';
$dom->parse('<div><p id="☃" /></div>');
$dom->at('#☃')->replace_inner('♥');
is "$dom", '<div><p id="☃">♥</p></div>', 'right text';
$dom->parse('<div>foo<p>lalala</p>bar</div>');
$dom->replace_inner('♥');
is "$dom", '♥', 'right text';
$dom->replace_inner('<div>foo<p>lalala</p>bar</div>');
is "$dom", '<div>foo<p>lalala</p>bar</div>', 'right text';
$dom->replace_inner('');
is "$dom", '', 'right text';
$dom->replace_inner('<div>foo<p>lalala</p>bar</div>');
is "$dom", '<div>foo<p>lalala</p>bar</div>', 'right text';

# Mixed search and tree walk
$dom->parse(<<EOF);
<table>
  <tr>
    <td>text1</td>
    <td>text2</td>
  </tr>
</table>
EOF
my @data;
for my $tr ($dom->find('table tr')->each) {
  for my $td (@{$tr->children}) {
    push @data, $td->type, $td->all_text;
  }
}
is $data[0], 'td',    'right tag';
is $data[1], 'text1', 'right text';
is $data[2], 'td',    'right tag';
is $data[3], 'text2', 'right text';
is $data[4], undef,   'no tag';

# RSS
$dom->parse(<<EOF);
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
  <channel>
    <title>Test Blog</title>
    <link>http://blog.kraih.com</link>
    <description>lalala</description>
    <generator>Mojolicious</generator>
    <item>
      <pubDate>Mon, 12 Jul 2010 20:42:00</pubDate>
      <title>Works!</title>
      <link>http://blog.kraih.com/test</link>
      <guid>http://blog.kraih.com/test</guid>
      <description>
        <![CDATA[<p>trololololo>]]>
      </description>
      <my:extension foo:id="works">
        <![CDATA[
          [awesome]]
        ]]>
      </my:extension>
    </item>
  </channel>
</rss>
EOF
is $dom->find('rss')->[0]->attrs('version'), '2.0', 'right version';
is $dom->at('extension')->attrs('foo:id'), 'works', 'right id';
like $dom->at('#works')->text,       qr/\[awesome\]\]/, 'right text';
like $dom->at('[id="works"]')->text, qr/\[awesome\]\]/, 'right text';
is $dom->find('description')->[1]->text, '<p>trololololo>', 'right text';
is $dom->at('pubdate')->text,       'Mon, 12 Jul 2010 20:42:00', 'right text';
like $dom->at('[id*="ork"]')->text, qr/\[awesome\]\]/,           'right text';
like $dom->at('[id*="orks"]')->text, qr/\[awesome\]\]/, 'right text';
like $dom->at('[id*="work"]')->text, qr/\[awesome\]\]/, 'right text';
like $dom->at('[id*="or"]')->text,   qr/\[awesome\]\]/, 'right text';

# Yadis
$dom->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>
<XRDS xmlns="xri://$xrds">
  <XRD xmlns="xri://$xrd*($v*2.0)">
    <Service>
      <Type>http://o.r.g/sso/2.0</Type>
    </Service>
    <Service>
      <Type>http://o.r.g/sso/1.0</Type>
    </Service>
  </XRD>
</XRDS>
EOF
is $dom->at('xrds')->namespace, 'xri://$xrds',         'right namespace';
is $dom->at('xrd')->namespace,  'xri://$xrd*($v*2.0)', 'right namespace';
my $s = $dom->find('xrds xrd service');
is $s->[0]->at('type')->text, 'http://o.r.g/sso/2.0', 'right text';
is $s->[0]->namespace, 'xri://$xrd*($v*2.0)', 'right namespace';
is $s->[1]->at('type')->text, 'http://o.r.g/sso/1.0', 'right text';
is $s->[1]->namespace, 'xri://$xrd*($v*2.0)', 'right namespace';
is $s->[2], undef, 'no text';

# Yadis (with namespace)
$dom->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service>
      <Type>http://o.r.g/sso/3.0</Type>
    </Service>
    <xrds:Service>
      <Type>http://o.r.g/sso/4.0</Type>
    </xrds:Service>
  </XRD>
  <XRD>
    <Service>
      <Type>http://o.r.g/sso/2.0</Type>
    </Service>
    <Service>
      <Type>http://o.r.g/sso/1.0</Type>
    </Service>
  </XRD>
</xrds:XRDS>
EOF
is $dom->at('xrds')->namespace, 'xri://$xrds',         'right namespace';
is $dom->at('xrd')->namespace,  'xri://$xrd*($v*2.0)', 'right namespace';
$s = $dom->find('xrds xrd service');
is $s->[0]->at('type')->text, 'http://o.r.g/sso/3.0', 'right text';
is $s->[0]->namespace, 'xri://$xrd*($v*2.0)', 'right namespace';
is $s->[1]->at('type')->text, 'http://o.r.g/sso/4.0', 'right text';
is $s->[1]->namespace, 'xri://$xrds', 'right namespace';
is $s->[2]->at('type')->text, 'http://o.r.g/sso/2.0', 'right text';
is $s->[2]->namespace, 'xri://$xrd*($v*2.0)', 'right namespace';
is $s->[3]->at('type')->text, 'http://o.r.g/sso/1.0', 'right text';
is $s->[3]->namespace, 'xri://$xrd*($v*2.0)', 'right namespace';
is $s->[4], undef, 'no text';

# Result and iterator order
$dom->parse('<a><b>1</b></a><b>2</b><b>3</b>');
my @numbers;
$dom->find("b")->each(sub { push @numbers, pop, shift->text });
is_deeply \@numbers, [1, 1, 2, 2, 3, 3], 'right order';

# Attributes on multiple lines
$dom->parse("<div test=23 id='a' \n class='x' foo=bar />");
is $dom->at('div.x')->attrs('test'),        23,  'right attribute';
is $dom->at('[foo="bar"]')->attrs('class'), 'x', 'right attribute';

# Markup characters in attribute values
$dom->parse(qq/<div id="<a>" \n test='='>Test<div id='><' \/><\/div>/);
is $dom->at('div[id="<a>"]')->attrs->{test}, '=', 'right attribute';
is $dom->at('[id="<a>"]')->text, 'Test', 'right text';
is $dom->at('[id="><"]')->attrs->{id}, '><', 'right attribute';

# Empty attributes
$dom->parse(qq/<div test="" test2='' \/>/);
is $dom->at('div')->attrs->{test},  '', 'empty attribute value';
is $dom->at('div')->attrs->{test2}, '', 'empty attribute value';

# Whitespaces before closing bracket
$dom->parse(qq/<div >content<\/div>/);
ok $dom->at('div'), 'tag found';
is $dom->at('div')->text,      'content', 'right text';
is $dom->at('div')->inner_xml, 'content', 'right text';

# Class with hyphen
$dom->parse(qq/<div class="a">A<\/div><div class="a-1">A1<\/div>/);
@div = ();
$dom->find('.a')->each(sub { push @div, shift->text });
is_deeply \@div, ['A'], 'found first element only';
@div = ();
$dom->find('.a-1')->each(sub { push @div, shift->text });
is_deeply \@div, ['A1'], 'found last element only';

# Defined but false text
$dom->parse(
  '<div><div id="a">A</div><div id="b">B</div></div><div id="0">0</div>');
@div = ();
$dom->find('div[id]')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A B 0/], 'found all div elements with id';

# Empty tags
$dom->parse('<hr /><br/><br id="br"/><br />');
is "$dom", '<hr /><br /><br id="br" /><br />', 'right result';
is $dom->at('br')->inner_xml, '', 'empty result';

# Inner XML
$dom->parse('<a>xxx<x>x</x>xxx</a>');
is $dom->at('a')->inner_xml, 'xxx<x>x</x>xxx', 'right result';
is $dom->inner_xml, '<a>xxx<x>x</x>xxx</a>', 'right result';

# Multiple selectors
$dom->parse('<div id="a">A</div><div id="b">B</div><div id="c">C</div>');
@div = ();
$dom->find('#a, #c')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A C/], 'found all div elements with the right ids';
@div = ();
$dom->find('div#a, div#b')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A B/], 'found all div elements with the right ids';
@div = ();
$dom->find('div[id="a"], div[id="c"]')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A C/], 'found all div elements with the right ids';
$dom->parse('<div id="☃">A</div><div id="b">B</div><div id="♥x">C</div>');
@div = ();
$dom->find('#☃, #♥x')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A C/], 'found all div elements with the right ids';
@div = ();
$dom->find('div#☃, div#b')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A B/], 'found all div elements with the right ids';
@div = ();
$dom->find('div[id="☃"], div[id="♥x"]')
  ->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A C/], 'found all div elements with the right ids';

# Multiple attributes
$dom->parse(<<EOF);
<div foo="bar" bar="baz">A</div>
<div foo="bar">B</div>
<div foo="bar" bar="baz">C</div>
<div foo="baz" bar="baz">D</div>
EOF
@div = ();
$dom->find('div[foo="bar"][bar="baz"]')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A C/], 'found all div elements with the right atributes';
@div = ();
$dom->find('div[foo^="b"][foo$="r"]')->each(sub { push @div, shift->text });
is_deeply \@div, [qw/A B C/],
  'found all div elements with the right atributes';

# Pseudo classes
$dom->parse(<<EOF);
<form action="/foo">
    <input type="text" name="user" value="test" />
    <input type="checkbox" checked="checked" name="groovy">
    <select name="a">
        <option value="b">b</option>
        <optgroup label="c">
            <option value="d">d</option>
            <option selected="selected" value="e">E</option>
            <option value="f">f</option>
        </optgroup>
        <option value="g">g</option>
    </select>
    <input type="submit" value="Ok!" />
</form>
EOF
is($dom->find(':root')->[0]->type,             'form',   'right type');
is($dom->find('*:root')->[0]->type,            'form',   'right type');
is($dom->find('form:root')->[0]->type,         'form',   'right type');
is($dom->find(':root')->[1],                   undef,    'no element');
is($dom->find(':checked')->[0]->attrs->{name}, 'groovy', 'right name');
is($dom->find('option:checked')->[0]->attrs->{value},    'e', 'right value');
is($dom->find(':checked')->[1]->text,                    'E', 'right text');
is($dom->find('*:checked')->[1]->text,                   'E', 'right text');
is($dom->find(':checked[value="e"]')->[0]->text,         'E', 'right text');
is($dom->find('*:checked[value="e"]')->[0]->text,        'E', 'right text');
is($dom->find('option:checked[value="e"]')->[0]->text,   'E', 'right text');
is($dom->at('optgroup option:checked[value="e"]')->text, 'E', 'right text');
is($dom->at('select option:checked[value="e"]')->text,   'E', 'right text');
is($dom->at('select :checked[value="e"]')->text,         'E', 'right text');
is($dom->at('optgroup > :checked[value="e"]')->text,     'E', 'right text');
is($dom->at('select *:checked[value="e"]')->text,        'E', 'right text');
is($dom->at('optgroup > *:checked[value="e"]')->text,    'E', 'right text');
is($dom->find(':checked[value="e"]')->[1],        undef,    'no element');
is($dom->find(':empty')->[0]->attrs->{name},      'user',   'right name');
is($dom->find('input:empty')->[0]->attrs->{name}, 'user',   'right name');
is($dom->at(':empty[type^="ch"]')->attrs->{name}, 'groovy', 'right name');

# More pseudo classes
$dom->parse(<<EOF);
<ul>
    <li>A</li>
    <li>B</li>
    <li>C</li>
    <li>D</li>
    <li>E</li>
    <li>F</li>
    <li>G</li>
    <li>H</li>
</ul>
EOF
my @li;
$dom->find('li:nth-child(odd)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A C E G/], 'found all odd li elements';
@li = ();
$dom->find('li:nth-last-child(odd)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/B D F H/], 'found all odd li elements';
is($dom->find(':nth-child(odd)')->[0]->type,       'ul', 'right type');
is($dom->find(':nth-child(odd)')->[1]->text,       'A',  'right text');
is($dom->find(':nth-child(1)')->[0]->type,         'ul', 'right type');
is($dom->find(':nth-child(1)')->[1]->text,         'A',  'right text');
is($dom->find(':nth-last-child(odd)')->[0]->type,  'ul', 'right type');
is($dom->find(':nth-last-child(odd)')->[-1]->text, 'H',  'right text');
is($dom->find(':nth-last-child(1)')->[0]->type,    'ul', 'right type');
is($dom->find(':nth-last-child(1)')->[1]->text,    'H',  'right text');
@li = ();
$dom->find('li:nth-child(2n+1)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A C E G/], 'found all odd li elements';
@li = ();
$dom->find('li:nth-child(2n + 1)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A C E G/], 'found all odd li elements';
@li = ();
$dom->find('li:nth-last-child(2n+1)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/B D F H/], 'found all odd li elements';
@li = ();
$dom->find('li:nth-child(even)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/B D F H/], 'found all even li elements';
@li = ();
$dom->find('li:nth-last-child(even)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A C E G/], 'found all even li elements';
@li = ();
$dom->find('li:nth-child(2n+2)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/B D F H/], 'found all even li elements';
@li = ();
$dom->find('li:nth-child( 2n + 2 )')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/B D F H/], 'found all even li elements';
@li = ();
$dom->find('li:nth-last-child(2n+2)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A C E G/], 'found all even li elements';
@li = ();
$dom->find('li:nth-child(4n+1)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A E/], 'found the right li elements';
@li = ();
$dom->find('li:nth-last-child(4n+1)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/D H/], 'found the right li elements';
@li = ();
$dom->find('li:nth-child(4n+4)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/D H/], 'found the right li element';
@li = ();
$dom->find('li:nth-last-child(4n+4)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A E/], 'found the right li element';
@li = ();
$dom->find('li:nth-child(4n)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/D H/], 'found the right li element';
@li = ();
$dom->find('li:nth-child( 4n )')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/D H/], 'found the right li element';
@li = ();
$dom->find('li:nth-last-child(4n)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A E/], 'found the right li element';
@li = ();
$dom->find('li:nth-child(5n-2)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/C H/], 'found the right li element';
@li = ();
$dom->find('li:nth-child( 5n - 2 )')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/C H/], 'found the right li element';
@li = ();
$dom->find('li:nth-last-child(5n-2)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A F/], 'found the right li element';
@li = ();
$dom->find('li:nth-child(-n+3)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A B C/], 'found first three li elements';
@li = ();
$dom->find('li:nth-child( -n + 3 )')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A B C/], 'found first three li elements';
@li = ();
$dom->find('li:nth-last-child(-n+3)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/F G H/], 'found last three li elements';
@li = ();
$dom->find('li:nth-child(-1n+3)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A B C/], 'found first three li elements';
@li = ();
$dom->find('li:nth-last-child(-1n+3)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/F G H/], 'found first three li elements';
@li = ();
$dom->find('li:nth-child(3n)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/C F/], 'found every third li elements';
@li = ();
$dom->find('li:nth-last-child(3n)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/C F/], 'found every third li elements';
@li = ();
$dom->find('li:nth-child(3)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/C/], 'found third li element';
@li = ();
$dom->find('li:nth-last-child(3)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/F/], 'found third last li element';
@li = ();
$dom->find('li:nth-child(1n+0)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A B C D E F G/], 'found first three li elements';
@li = ();
$dom->find('li:nth-child(n+0)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A B C D E F G/], 'found first three li elements';
@li = ();
$dom->find('li:nth-child(n)')->each(sub { push @li, shift->text });
is_deeply \@li, [qw/A B C D E F G/], 'found first three li elements';

# Even more pseudo classes
$dom->parse(<<EOF);
<ul>
    <li>A</li>
    <p>B</p>
    <li class="test ♥">C</li>
    <p>D</p>
    <li>E</li>
    <li>F</li>
    <p>G</p>
    <li>H</li>
    <li>I</li>
</ul>
<div>
    <div class="☃">J</div>
</div>
<div>
    <a href="http://mojolicio.us">Mojo!</a>
    <div class="☃">K</div>
    <a href="http://mojolicio.us">Mojolicious!</a>
</div>
EOF
my @e;
$dom->find('ul :nth-child(odd)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A C E G I/], 'found all odd elements';
@e = ();
$dom->find('li:nth-of-type(odd)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A E H/], 'found all odd li elements';
@e = ();
$dom->find('li:nth-last-of-type(odd)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/C F I/], 'found all odd li elements';
@e = ();
$dom->find('p:nth-of-type(odd)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/B G/], 'found all odd p elements';
@e = ();
$dom->find('p:nth-last-of-type(odd)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/B G/], 'found all odd li elements';
@e = ();
$dom->find('ul :nth-child(1)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A/], 'found first child';
@e = ();
$dom->find('ul :first-child')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A/], 'found first child';
@e = ();
$dom->find('p:nth-of-type(1)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/B/], 'found first child';
@e = ();
$dom->find('p:first-of-type')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/B/], 'found first child';
@e = ();
$dom->find('li:nth-of-type(1)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A/], 'found first child';
@e = ();
$dom->find('li:first-of-type')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A/], 'found first child';
@e = ();
$dom->find('ul :nth-last-child(-n+1)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/I/], 'found last child';
@e = ();
$dom->find('ul :last-child')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/I/], 'found last child';
@e = ();
$dom->find('p:nth-last-of-type(-n+1)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/G/], 'found last child';
@e = ();
$dom->find('p:last-of-type')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/G/], 'found last child';
@e = ();
$dom->find('li:nth-last-of-type(-n+1)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/I/], 'found last child';
@e = ();
$dom->find('li:last-of-type')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/I/], 'found last child';
@e = ();
$dom->find('ul :nth-child(-n+3):not(li)')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/B/], 'found first p element';
@e = ();
$dom->find('ul :nth-child(-n+3):not(:first-child)')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/B C/], 'found second and third element';
@e = ();
$dom->find('ul :nth-child(-n+3):not(.♥)')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A B/], 'found first and second element';
@e = ();
$dom->find('ul :nth-child(-n+3):not([class$="♥"])')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A B/], 'found first and second element';
@e = ();
$dom->find('ul :nth-child(-n+3):not(li[class$="♥"])')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A B/], 'found first and second element';
@e = ();
$dom->find('ul :nth-child(-n+3):not([class$="♥"][class^="test"])')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A B/], 'found first and second element';
@e = ();
$dom->find('ul :nth-child(-n+3):not(*[class$="♥"])')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/A B/], 'found first and second element';
@e = ();
$dom->find('ul :nth-child(-n+3):not(:nth-child(-n+2))')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/C/], 'found third element';
@e = ();
$dom->find('ul :nth-child(-n+3):not(:nth-child(1)):not(:nth-child(2))')
  ->each(sub { push @e, shift->text });
is_deeply \@e, [qw/C/], 'found third element';
@e = ();
$dom->find(':only-child')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/J/], 'found only child';
@e = ();
$dom->find('div :only-of-type')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/J K/], 'found only child';
@e = ();
$dom->find('div:only-child')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/J/], 'found only child';
@e = ();
$dom->find('div div:only-of-type')->each(sub { push @e, shift->text });
is_deeply \@e, [qw/J K/], 'found only child';

# Sibling combinator
$dom->parse(<<EOF);
<ul>
    <li>A</li>
    <p>B</p>
    <li>C</li>
</ul>
<h1>D</h1>
<p id="♥">E</p>
<p id="☃">F</p>
<div>G</div>
EOF
is($dom->at('li ~ p')->text,                            'B',   'right text');
is($dom->at('li + p')->text,                            'B',   'right text');
is($dom->at('h1 ~ p ~ p')->text,                        'F',   'right text');
is($dom->at('h1 + p ~ p')->text,                        'F',   'right text');
is($dom->at('h1 ~ p + p')->text,                        'F',   'right text');
is($dom->at('h1 + p + p')->text,                        'F',   'right text');
is($dom->at('ul > li ~ li')->text,                      'C',   'right text');
is($dom->at('ul li ~ li')->text,                        'C',   'right text');
is($dom->at('ul li li'),                                undef, 'no result');
is($dom->at('ul ~ li ~ li'),                            undef, 'no result');
is($dom->at('ul + li ~ li'),                            undef, 'no result');
is($dom->at('ul > li + li'),                            undef, 'no result');
is($dom->at('h1 ~ div')->text,                          'G',   'right text');
is($dom->at('h1 + div'),                                undef, 'no result');
is($dom->at('p + div')->text,                           'G',   'right text');
is($dom->at('ul + h1 + p + p + div')->text,             'G',   'right text');
is($dom->at('ul + h1 ~ p + div')->text,                 'G',   'right text');
is($dom->at('h1 ~ #♥')->text,                         'E',   'right text');
is($dom->at('h1 + #♥')->text,                         'E',   'right text');
is($dom->at('#♥ ~ #☃')->text,                       'F',   'right text');
is($dom->at('#♥ + #☃')->text,                       'F',   'right text');
is($dom->at('#♥ > #☃'),                             undef, 'no result');
is($dom->at('#♥ #☃'),                               undef, 'no result');
is($dom->at('#♥ + #☃ + :nth-last-child(1)')->text,  'G',   'right text');
is($dom->at('#♥ ~ #☃ + :nth-last-child(1)')->text,  'G',   'right text');
is($dom->at('#♥ + #☃ ~ :nth-last-child(1)')->text,  'G',   'right text');
is($dom->at('#♥ ~ #☃ ~ :nth-last-child(1)')->text,  'G',   'right text');
is($dom->at('#♥ + :nth-last-child(2)')->text,         'F',   'right text');
is($dom->at('#♥ ~ :nth-last-child(2)')->text,         'F',   'right text');
is($dom->at('#♥ + #☃ + *:nth-last-child(1)')->text, 'G',   'right text');
is($dom->at('#♥ ~ #☃ + *:nth-last-child(1)')->text, 'G',   'right text');
is($dom->at('#♥ + #☃ ~ *:nth-last-child(1)')->text, 'G',   'right text');
is($dom->at('#♥ ~ #☃ ~ *:nth-last-child(1)')->text, 'G',   'right text');
is($dom->at('#♥ + *:nth-last-child(2)')->text,        'F',   'right text');
is($dom->at('#♥ ~ *:nth-last-child(2)')->text,        'F',   'right text');

# Adding nodes
$dom->parse(<<EOF);
<ul>
    <li>A</li>
    <p>B</p>
    <li>C</li>
</ul>
<div>D</div>
EOF
$dom->at('li')->add_after('<p>A1</p>23');
is "$dom", <<EOF, 'right result';
<ul>
    <li>A</li><p>A1</p>23
    <p>B</p>
    <li>C</li>
</ul>
<div>D</div>
EOF
$dom->at('li')->add_before('24')->add_before('<div>A-1</div>25');
is "$dom", <<EOF, 'right result';
<ul>
    24<div>A-1</div>25<li>A</li><p>A1</p>23
    <p>B</p>
    <li>C</li>
</ul>
<div>D</div>
EOF
is $dom->at('div')->text, 'A-1', 'right text';
is $dom->at('iv'), undef, 'no result';
$dom->add_before('l')->add_before('alal')->add_before('a');
is "$dom", <<EOF, 'no change';
<ul>
    24<div>A-1</div>25<li>A</li><p>A1</p>23
    <p>B</p>
    <li>C</li>
</ul>
<div>D</div>
EOF
$dom->add_after('lalala');
is "$dom", <<EOF, 'no change';
<ul>
    24<div>A-1</div>25<li>A</li><p>A1</p>23
    <p>B</p>
    <li>C</li>
</ul>
<div>D</div>
EOF
$dom->find('div')->each(sub { shift->add_after('works') });
is "$dom", <<EOF, 'right result';
<ul>
    24<div>A-1</div>works25<li>A</li><p>A1</p>23
    <p>B</p>
    <li>C</li>
</ul>
<div>D</div>works
EOF

# Optional "head" and "body" tags
$dom->parse(<<EOF);
<html>
  <head>
    <title>foo</title>
  <body>bar
EOF
is $dom->at('html > head > title')->text, 'foo',   'right text';
is $dom->at('html > body')->text,         "bar\n", 'right text';

# Optional "li" tag
$dom->parse(<<EOF);
<ul>
  <li>A</li>
  <LI>B
  <li>C</li>
  <li>D
  <li>E
</ul>
EOF
is $dom->find('ul > li')->[0]->text, 'A',     'right text';
is $dom->find('ul > li')->[1]->text, "B\n  ", 'right text';
is $dom->find('ul > li')->[2]->text, 'C',     'right text';
is $dom->find('ul > li')->[3]->text, "D\n  ", 'right text';
is $dom->find('ul > li')->[4]->text, "E\n",   'right text';

# Optional "p" tag
$dom->parse(<<EOF);
<div>
  <p>A</p>
  <P>B
  <p>C</p>
  <p>D<div>X</div>
  <p>E<img src="foo.png">
  <p>F<br>G
  <p>H
</div>
EOF
is $dom->find('div > p')->[0]->text, 'A',      'right text';
is $dom->find('div > p')->[1]->text, "B\n  ",  'right text';
is $dom->find('div > p')->[2]->text, 'C',      'right text';
is $dom->find('div > p')->[3]->text, 'D',      'right text';
is $dom->find('div > p')->[4]->text, 'E',      'right text';
is $dom->find('div > p')->[5]->text, "FG\n  ", 'right text';
is $dom->find('div > p')->[6]->text, "H\n",    'right text';
is $dom->at('div > p > img')->attrs->{src}, 'foo.png', 'right attribute';
is $dom->at('div > div')->text, 'X', 'right text';

# Optional "dt" and "dd" tags
$dom->parse(<<EOF);
<dl>
  <dt>A</dt>
  <DD>B
  <dt>C</dt>
  <dd>D
  <dt>E
  <dd>F
</dl>
EOF
is $dom->find('dl > dt')->[0]->text, 'A',     'right text';
is $dom->find('dl > dd')->[0]->text, "B\n  ", 'right text';
is $dom->find('dl > dt')->[1]->text, 'C',     'right text';
is $dom->find('dl > dd')->[1]->text, "D\n  ", 'right text';
is $dom->find('dl > dt')->[2]->text, "E\n  ", 'right text';
is $dom->find('dl > dd')->[2]->text, "F\n",   'right text';

# Optional "rp" and "rt" tags
$dom->parse(<<EOF);
<ruby>
  <rp>A</rp>
  <RT>B
  <rp>C</rp>
  <rt>D
  <rp>E
  <rt>F
</ruby>
EOF
is $dom->find('ruby > rp')->[0]->text, 'A',     'right text';
is $dom->find('ruby > rt')->[0]->text, "B\n  ", 'right text';
is $dom->find('ruby > rp')->[1]->text, 'C',     'right text';
is $dom->find('ruby > rt')->[1]->text, "D\n  ", 'right text';
is $dom->find('ruby > rp')->[2]->text, "E\n  ", 'right text';
is $dom->find('ruby > rt')->[2]->text, "F\n",   'right text';

# Optional "optgroup" and "option" tags
$dom->parse(<<EOF);
<div>
  <optgroup>A
    <option id="foo">B
    <option>C</option>
    <option>D
  <OPTGROUP>E
    <option>F
  <optgroup>G
    <option>H
</div>
EOF
is $dom->find('div > optgroup')->[0]->text,          "A\n    ", 'right text';
is $dom->find('div > optgroup > #foo')->[0]->text,   "B\n    ", 'right text';
is $dom->find('div > optgroup > option')->[1]->text, 'C',       'right text';
is $dom->find('div > optgroup > option')->[2]->text, "D\n  ",   'right text';
is $dom->find('div > optgroup')->[1]->text,          "E\n    ", 'right text';
is $dom->find('div > optgroup > option')->[3]->text, "F\n  ",   'right text';
is $dom->find('div > optgroup')->[2]->text,          "G\n    ", 'right text';
is $dom->find('div > optgroup > option')->[4]->text, "H\n",     'right text';

# Optional "colgroup" tag
$dom->parse(<<EOF);
<table>
  <col id=morefail>
  <col id=fail>
  <colgroup>
    <col id=foo>
    <col class=foo>
  <colgroup>
    <col id=bar>
</table>
EOF
is $dom->find('table > col')->[0]->attrs->{id}, 'morefail', 'right attribute';
is $dom->find('table > col')->[1]->attrs->{id}, 'fail',     'right attribute';
is $dom->find('table > colgroup > col')->[0]->attrs->{id}, 'foo',
  'right attribute';
is $dom->find('table > colgroup > col')->[1]->attrs->{class}, 'foo',
  'right attribute';
is $dom->find('table > colgroup > col')->[2]->attrs->{id}, 'bar',
  'right attribute';

# Optional "thead", "tbody", "tfoot", "tr", "th" and "td" tags
$dom->parse(<<EOF);
<table>
  <thead>
    <tr>
      <th>A</th>
      <th>D
  <tbody>
    <tr>
      <td>B
  <tfoot>
    <tr>
      <td>C
</table>
EOF
is $dom->at('table > thead > tr > th')->text, 'A', 'right text';
is $dom->find('table > thead > tr > th')->[1]->text, "D\n  ", 'right text';
is $dom->at('table > tbody > tr > td')->text, "B\n  ", 'right text';
is $dom->at('table > tfoot > tr > td')->text, "C\n",   'right text';

# Optional "colgroup", "thead", "tbody", "tr", "th" and "td" tags
$dom->parse(<<EOF);
<table>
  <col id=morefail>
  <col id=fail>
  <colgroup>
    <col id=foo />
    <col class=foo>
  <colgroup>
    <col id=bar>
  </colgroup>
  <thead>
    <tr>
      <th>A</th>
      <th>D
  <tbody>
    <tr>
      <td>B
</table>
EOF
is $dom->find('table > col')->[0]->attrs->{id}, 'morefail', 'right attribute';
is $dom->find('table > col')->[1]->attrs->{id}, 'fail',     'right attribute';
is $dom->find('table > colgroup > col')->[0]->attrs->{id}, 'foo',
  'right attribute';
is $dom->find('table > colgroup > col')->[1]->attrs->{class}, 'foo',
  'right attribute';
is $dom->find('table > colgroup > col')->[2]->attrs->{id}, 'bar',
  'right attribute';
is $dom->at('table > thead > tr > th')->text, 'A', 'right text';
is $dom->find('table > thead > tr > th')->[1]->text, "D\n  ", 'right text';
is $dom->at('table > tbody > tr > td')->text, "B\n", 'right text';

# Optional "colgroup", "tbody", "tr", "th" and "td" tags
$dom->parse(<<EOF);
<table>
  <colgroup>
    <col id=foo />
    <col class=foo>
  <colgroup>
    <col id=bar>
  </colgroup>
  <tbody>
    <tr>
      <td>B
</table>
EOF
is $dom->find('table > colgroup > col')->[0]->attrs->{id}, 'foo',
  'right attribute';
is $dom->find('table > colgroup > col')->[1]->attrs->{class}, 'foo',
  'right attribute';
is $dom->find('table > colgroup > col')->[2]->attrs->{id}, 'bar',
  'right attribute';
is $dom->at('table > tbody > tr > td')->text, "B\n", 'right text';

# Optional "tr" and "td" tags
$dom->parse(<<EOF);
<table>
    <tr>
      <td>A
      <td>B</td>
    <tr>
      <td>C
    </tr>
    <tr>
      <td>D
</table>
EOF
is $dom->find('table > tr > td')->[0]->text, "A\n      ", 'right text';
is $dom->find('table > tr > td')->[1]->text, 'B',         'right text';
is $dom->find('table > tr > td')->[2]->text, "C\n    ",   'right text';
is $dom->find('table > tr > td')->[3]->text, "D\n",       'right text';
