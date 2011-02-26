package Mojolicious::Plugin::EplRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Template;
use Mojo::Util 'md5_sum';

# "Clever things make people feel stupid and unexpected things make them feel
#  scared."
sub register {
  my ($self, $app) = @_;

  # Add "epl" handler
  $app->renderer->add_handler(
    epl => sub {
      my ($r, $c, $output, $options) = @_;

      # Inline
      my $inline = $options->{inline};

      # Template
      my $path = $r->template_path($options);
      $path = md5_sum $inline if defined $inline;
      return unless defined $path;

      # Cache
      my $cache = $r->cache;
      my $key   = delete $options->{cache} || $path;
      my $mt    = $cache->get($key);

      # Initialize
      $mt ||= Mojo::Template->new;

      # Cached
      if ($mt->compiled) { $$output = $mt->interpret($c) }

      # Not cached
      else {

        # Inline
        if (defined $inline) { $$output = $mt->render($inline, $c) }

        # File
        else {

          # Encoding
          $mt->encoding($r->encoding) if $r->encoding;

          # Name
          return unless my $t = $r->template_name($options);

          # Try template
          if (-r $path) { $$output = $mt->render_file($path, $c) }

          # Try DATA section
          elsif (my $d = $r->get_inline_template($options, $t)) {
            $$output = $mt->render($d, $c);
          }

          # No template
          else {
            $c->app->log->debug(qq/Template "$t" not found./)
              and return;
          }
        }

        # Cache
        $cache->set($key => $mt);
      }

      # Exception
      if (ref $$output) {
        my $e = $$output;
        $$output = '';
        $c->render_exception($e);
      }

      # Success or exception
      return ref $$output ? 0 : 1;
    }
  );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::EplRenderer - EPL Renderer Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('epl_renderer');

  # Mojolicious::Lite
  plugin 'epl_renderer';

=head1 DESCRIPTION

L<Mojolicous::Plugin::EplRenderer> is a renderer for C<epl> templates.
C<epl> templates are pretty much just raw L<Mojo::Template>.
This is a core plugin, that means it is always enabled and its code a good
example for learning to build new plugins.

=head1 METHODS

L<Mojolicious::Plugin::EplRenderer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register renderer in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
