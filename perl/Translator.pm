package Translator;

use Moose;
use warnings FATAL => 'all';

use Module::Pluggable
    require => 1,
    inner => 0,
    search_path => ['Translator'],
    sub_name => 'scheme_handlers';

use Carp qw(confess);
use Memoize qw();
use URI::URL qw();


sub resolve_scalar_or_url {
    my $self = shift;
    my $string = shift;

    my $url = new URI::URL $string;

    if ($url->scheme) {
        return $self->_resolve_url($url);
    } else {
        return $string;
    }
}


sub _resolve_url {
    my $self = shift;
    my $url = shift;

    unless ($url->scheme) {
        confess sprintf("No scheme specified in '%s'", $url);
    }

    my $handler = $self->_get_handler($url->scheme);
    return $handler->resolve($url);
}

sub _get_handler {
    my $self = shift;
    my $scheme = shift;

    my $handlers = $self->_load_scheme_handlers();
    unless ($handlers->{$scheme}) {
        my $available_handlers = join("\n", map {"$_ => " . $handlers->{$_}} keys %{$handlers});
        confess sprintf("No handler was found for scheme (%s).  Available handlers are:%s",
            $scheme, $available_handlers);
    }
}

sub _load_scheme_handlers {
    my $self = shift;

    my %handlers;
    for my $handler ($self->scheme_handlers) {
        my $scheme = $handler->scheme;
        if (!exists($handlers{$scheme})) {
            $handlers{$scheme} = $handler;
        } else {
            confess sprintf("Attempted to register two handlers for scheme (%s): %s",
                $scheme, join("\n", $handlers{$scheme}, $handler));
        }
    }
    return \%handlers;
}
Memoize::memoize('_load_scheme_handlers');

1;
