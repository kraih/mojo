#!/usr/bin/env perl
use Mojo::Base -strict;

# Disable Bonjour, IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_IOWATCHER} = 'Mojo::IOWatcher';
}

use Test::More tests => 317;

# "Woohoo, time to go clubbin'! Baby seals here I come!"
use Mojolicious::Lite;
use Test::Mojo;

# /rest
under '/rest';

# GET
get sub {
  my $self = shift;
  $self->respond_to(
    json => sub { $self->render_json({just => 'works'}) },
    html => sub { $self->render_data('<html><body>works') },
    xml  => sub { $self->render_data('<just>works</just>') }
  ) or $self->rendered(204);
};

# POST
post sub {
  my $self = shift;
  $self->respond_to(
    json => {json => {just => 'works too'}},
    html => {text => '<html><body>works too'},
    xml  => {data => '<just>works too</just>'},
    any => {text => 'works too', status => 201}
  );
};

# "Raise the solar sails! I'm going after that Mobius Dick!"
my $t = Test::Mojo->new;

# GET /rest
$t->get_ok('/rest')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest.html (html format)
$t->get_ok('/rest.html')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (accept html)
$t->get_ok('/rest', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (accept html again)
$t->get_ok('/rest', {Accept => 'Text/Html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest.html (accept html with format)
$t->get_ok('/rest.html', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest.json (accept html with wrong format)
$t->get_ok('/rest.json', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (accept html with quality)
$t->get_ok('/rest', {Accept => 'text/html;q=9'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (html query)
$t->get_ok('/rest?format=html')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (html format with query)
$t->get_ok('/rest.html?format=html')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (accept html with query)
$t->get_ok('/rest?format=html', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest (accept html with everything)
$t->get_ok('/rest.html?format=html', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works');

# GET /rest.json (json format)
$t->get_ok('/rest.json')->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works'});

# GET /rest (accept json)
$t->get_ok('/rest', {Accept => 'application/json'})->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest (accept json again)
$t->get_ok('/rest', {Accept => 'APPLICATION/JSON'})->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest.json (accept json with format)
$t->get_ok('/rest.json', {Accept => 'application/json'})->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest.png (accept json with wrong format)
$t->get_ok('/rest.png', {Accept => 'application/json'})->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest (accept json with quality)
$t->get_ok('/rest', {Accept => 'application/json;q=9'})->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest (json query)
$t->get_ok('/rest?format=json')->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest (json format with query)
$t->get_ok('/rest.json?format=json')->status_is(200)
  ->content_type_is('application/json')->json_content_is({just => 'works'});

# GET /rest (accept json with query)
$t->get_ok('/rest?format=json', {Accept => 'application/json'})
  ->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works'});

# GET /rest (accept json with everything)
$t->get_ok('/rest.json?format=json', {Accept => 'application/json'})
  ->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works'});

# GET /rest.xml (xml format)
$t->get_ok('/rest.xml')->status_is(200)->content_type_is('text/xml')
  ->text_is(just => 'works');

# GET /rest (accept xml)
$t->get_ok('/rest', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest (accept xml again)
$t->get_ok('/rest', {Accept => 'TEXT/XML'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest.xml (accept xml with format)
$t->get_ok('/rest.xml', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest.txt (accept xml with wrong format)
$t->get_ok('/rest.txt', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest (accept xml with quality)
$t->get_ok('/rest', {Accept => 'text/xml;q=9'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest (xml query)
$t->get_ok('/rest?format=xml')->status_is(200)->content_type_is('text/xml')
  ->text_is(just => 'works');

# GET /rest (xml format with query)
$t->get_ok('/rest.xml?format=xml')->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest (accept json with query)
$t->get_ok('/rest?format=xml', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest (accept json with everything)
$t->get_ok('/rest.xml?format=xml', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works');

# GET /rest (unsupported accept)
$t->get_ok('/rest', {Accept => 'image/png'})->status_is(204)->content_is('');

# POST /rest
$t->post_ok('/rest')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest.html (html format)
$t->post_ok('/rest.html')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html)
$t->post_ok('/rest', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html again)
$t->post_ok('/rest', {Accept => 'Text/Html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest.html (accept html with format)
$t->post_ok('/rest.html', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest.json (accept html with wrong format)
$t->post_ok('/rest.json', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html with quality)
$t->post_ok('/rest', {Accept => 'text/html;q=9'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (html query)
$t->post_ok('/rest?format=html')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (html format with query)
$t->post_ok('/rest.html?format=html')->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html with query)
$t->post_ok('/rest?format=html', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html with everything)
$t->post_ok('/rest.html?format=html', {Accept => 'text/html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (html form)
$t->post_form_ok('/rest' => {format => 'html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (html format with form)
$t->post_form_ok('/rest.html' => {format => 'html'})->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html with form)
$t->post_form_ok('/rest' => {format => 'html'} => {Accept => 'text/html'})
  ->status_is(200)->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest (accept html with everything, form alternative)
$t->post_form_ok(
  '/rest.html' => {format => 'html'} => {Accept => 'text/html'})
  ->status_is(200)->content_type_is('text/html;charset=UTF-8')
  ->text_is('html > body', 'works too');

# POST /rest.json (json format)
$t->post_ok('/rest.json')->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json)
$t->post_ok('/rest', {Accept => 'application/json'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json again)
$t->post_ok('/rest', {Accept => 'APPLICATION/JSON'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest.json (accept json with format)
$t->post_ok('/rest.json', {Accept => 'application/json'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest.png (accept json with wrong format)
$t->post_ok('/rest.png', {Accept => 'application/json'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json with quality)
$t->post_ok('/rest', {Accept => 'application/json;q=9'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (json query)
$t->post_ok('/rest?format=json')->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (json format with query)
$t->post_ok('/rest.json?format=json')->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json with query)
$t->post_ok('/rest?format=json', {Accept => 'application/json'})
  ->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json with everything)
$t->post_ok('/rest.json?format=json', {Accept => 'application/json'})
  ->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (json form)
$t->post_form_ok('/rest' => {format => 'json'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (json format with form)
$t->post_form_ok('/rest.json' => {format => 'json'})->status_is(200)
  ->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json with form)
$t->post_form_ok(
  '/rest' => {format => 'json'} => {Accept => 'application/json'})
  ->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest (accept json with everything, form alternative)
$t->post_form_ok(
  '/rest.json' => {format => 'json'} => {Accept => 'application/json'})
  ->status_is(200)->content_type_is('application/json')
  ->json_content_is({just => 'works too'});

# POST /rest.xml (xml format)
$t->post_ok('/rest.xml')->status_is(200)->content_type_is('text/xml')
  ->text_is(just => 'works too');

# POST /rest (accept xml)
$t->post_ok('/rest', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (accept xml again)
$t->post_ok('/rest', {Accept => 'TEXT/XML'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest.xml (accept xml with format)
$t->post_ok('/rest.xml', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest.txt (accept xml with wrong format)
$t->post_ok('/rest.txt', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (accept xml with quality)
$t->post_ok('/rest', {Accept => 'text/xml;q=9'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (xml query)
$t->post_ok('/rest?format=xml')->status_is(200)->content_type_is('text/xml')
  ->text_is(just => 'works too');

# POST /rest (xml format with query)
$t->post_ok('/rest.xml?format=xml')->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (accept json with query)
$t->post_ok('/rest?format=xml', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (accept json with everything)
$t->post_ok('/rest.xml?format=xml', {Accept => 'text/xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (xml form)
$t->post_form_ok('/rest' => {format => 'xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (xml format with form)
$t->post_form_ok('/rest.xml' => {format => 'xml'})->status_is(200)
  ->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (accept json with form)
$t->post_form_ok('/rest' => {format => 'xml'} => {Accept => 'text/xml'})
  ->status_is(200)->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (accept json with everything, form alternative)
$t->post_form_ok('/rest.xml' => {format => 'xml'} => {Accept => 'text/xml'})
  ->status_is(200)->content_type_is('text/xml')->text_is(just => 'works too');

# POST /rest (unsupported accept)
$t->post_ok('/rest', {Accept => 'image/png'})->status_is(201)
  ->content_type_is('text/html;charset=UTF-8')->content_is('works too');

# POST /rest (unsupported accept with supported query)
$t->post_ok('/rest?format=json', {Accept => 'image/png'})->status_is(201)
  ->content_type_is('text/html;charset=UTF-8')->content_is('works too');

# POST /rest.png (unsupported format)
$t->post_ok('/rest.png')->status_is(201)
  ->content_type_is('text/html;charset=UTF-8')->content_is('works too');

# POST /rest.png (unsupported format with supported query)
$t->post_ok('/rest.png?format=json')->status_is(201)
  ->content_type_is('text/html;charset=UTF-8')->content_is('works too');

# GET /nothing (does not exist)
$t->get_ok('/nothing', {Accept => 'image/png'})->status_is(404);
