package Dancer::Plugin::Stomp;
use strict;
use warnings;
use Dancer::Plugin;
use Memoize;
use Net::STOMP::Client;

# VERSION

memoize 'get_stomp_client';
memoize '_params';

sub get_stomp_client {
    my ($name) = @_;
    my %params = _params($name);
    my $host = $params{host} || $params{hostname}
        or die "The Stomp server host is missing";
    my $port = $params{port} || 61613;
    my $stomp = Net::STOMP::Client->new(host => $host, port => $port);
    return $stomp;
};

sub stomp_send {
    my ($name, $data);
    if (ref $_[0]) {
        $data = $_[0];
    } elsif (ref $_[1]) {
        ($name, $data) = @_;
    } else {
        die "stomp_send requires a data param";
    }
    my $stomp = get_stomp_client($name);
    my %params = _params($name);
    my %conn_info;
    $conn_info{login} = $params{login} if exists $params{login};
    $conn_info{passcode} = $params{passcode} if exists $params{passcode};
    $stomp->connect(%conn_info);
    $stomp->send(%$data);
    $stomp->disconnect();
}

sub _params {
    my ($name) = @_;
    my $config = plugin_setting;
    die "Stomp configuration is empty" unless %$config;
    if (not defined $name) {
        ($name) = keys %$config;
        $name = 'default' if $config->{default};
    }
    my $params = $config->{$name}
        or die "The Stomp client '$name' is not configured";
    return %$params;
}

register stomp => \&get_stomp_client;
register stomp_send => \&stomp_send;
register_plugin;

# ABSTRACT: A Dancer plugin for talking to STOMP message brokers.

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Stomp;

    post '/messages' => sub {
        stomp_send { destination => '/queue/foo', body => request->body };
    };

    dance;

=head1 DESCRIPTION

The goal of this module is to make it as easy as possible to interact with a
STOMP message broker.
STOMP stands for  Simple (or Streaming) Text Orientated Messaging Protocol.
It is a simple and standard protocol for messaging systems.
See L<http://stomp.github.com> for more details about the protocol.

=head1 KEYWORDS

=head2 stomp_send

    stomp_send \%data
    stomp_send name => \%data

This is a convenience function that handles connection details for you.
It sends your message using the default configured client.
If you have only one client configured, it is your default one.
If you have multiple clients configured, the one named C<default> will be used.
Doing this

    stomp_send { destination => '/queue/foo', body => 'hello' };

is the same as:

    stomp->connect(login => $login, passcode => $passcode);
    stomp->send(destination => '/queue/foo', body => 'hello');
    stomp->disconnect();

If you have multiple clients configured, you can distinguish between them
by providing the name of the client as the first argument, followed by
the data as the second argument:

    stomp_send foo => { destination => '/queue/foo', body => 'hello' };

=head2 stomp

    my $stomp = stomp
    my $stomp = stomp $name

This simply returns a L<Net::STOMP::Client> object.
You are responsible for connecting and disconnecting.
When no arguments are given, it returns a handle to the default configured
client.
You may provide a name if you have multiple clients configured.

=head1 CONFIGURATION

Configuration at a minimum requires a name and a host.
The following example defines one client named C<default>.

    plugins:
      Stomp:
        default:
          host: foo.com

Multiple clients can also be configured:

    plugins:
      Stomp:
        default:
          host: foo.com
        bar:
          host: bar.com
          port: 61613
          login: bob
          passcode: secret

The available configuration options for a client are:

=over

=item host - Required

This is the location of the STOMP server.
It can be an ip address or a hostname.

=item port - Optional, Default: 61613

=item login - Optional

=item passcode - Optional

=back

=head1 SEE ALSO

L<Net::STOMP::Client>, L<POE::Component::MessageQueue>,
L<http://stomp.github.com> 

=cut

1;
