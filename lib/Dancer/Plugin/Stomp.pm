package Dancer::Plugin::Stomp;
use strict;
use warnings;
use Dancer::Plugin;
use Net::Stomp;

# VERSION

my %stomps;

register stomp => sub {
    my $name = shift;
    my $config = plugin_setting;

    if (not defined $name) {
        ($name) = keys %$config or die "Stomp configuration is empty";
    }

    return $stomps{$name} if $stomps{$name};

    my $params = $config->{$name}
        or die "The Stomp client '$name' is not configured";

    my $hostname = $params->{hostname}
        or die "The Stomp server hostname is missing";

    my $port = 61613;
    $port = $params->{port} if exists $params->{port};

    my $stomp = Net::Stomp->new({ hostname => $hostname, port => $port });

    my $auto_connect = 1;
    $auto_connect = $params->{auto_connect} if exists $params->{auto_connect};

    if ($auto_connect) {
        my %conn_info;
        $conn_info{login} = $params->{login} if exists $params->{login};
        $conn_info{passcode} = $params->{passcode}
            if exists $params->{passcode};
        $stomp->connect(\%conn_info);
    }

    return $stomps{$name} = $stomp;
};

register_plugin;

# ABSTRACT: A Dancer plugin for talking to Stomp message brokers.

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Stomp;

    post '/messages' => sub {
        stomp->send({ destination => '/queue/foo', body => request->body });
    };

    dance;

=head1 DESCRIPTION

This module aims to make it as easy as possible to interact with a Stomp
message broker. It provides one new keyword, stomp, which returns a
Net::Stomp object.

=head1 CONFIGURATION

Configuration requires a hostname at a minimum.

    plugins:
      Stomp:
        foo:
          hostname: foo.com

The above configuration will allow you to send a message very simply:

    stomp->send({ destination => '/queue/foo', body => 'hello' });

Multiple Stomp clients can also be configured:

    plugins:
      Stomp:
        foo:
          hostname: foo.com
        bar:
          hostname: bar.com
          port: 61613
          login: bob
          passcode: secret
          auto_connect: 0


To distinguish between multiple stomp clients, you call stomp with a name:

    stomp('foo')->send( ... );
    stomp('bar')->send( ... );

The available configuration options for a given Stomp client are:

=over

=item hostname - Required

=item port - Optional, Default: 61613

=item login - Optional

=item passcode - Optional

=item auto_connect - Optional, Default: 1

=back

=head1 SEE ALSO

L<Net::Stomp>, L<POE::Component::MessageQueue>

=cut

1;
