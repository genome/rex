package Translator::GMS;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Spec qw();
use Manifest::Reader;
use Memoize qw();
use Process;

use Module::Pluggable
    instantiate => 'new',
    only => qr(Translator::GMS::[^:]+$),
    except => 'Translator::GMS::Object',
    search_path => ['Translator::GMS'],
    sub_name => 'type_handlers';

sub scheme {
    return 'gms';
}

sub resolve {
    my ($self, $url) = @_;

    if ($url->netloc) {
        confess sprintf("no handlers registered to handle the domain (%s)",
            $url->netloc);
    } else {
        my $handler = $self->_get_handler(_get_type($url));
        return $handler->resolve($url);
    }
}

sub _get_type {
    my $url = shift;
    my ($junk, $type) = $url->path_components;
    return $type;
}

sub _get_handler {
    my $self = shift;
    my $type = shift;

    my $handlers = $self->_load_type_handlers();
    unless ($handlers->{$type}) {
        my $available_handlers = join("\n", map {"$_ => " . $handlers->{$_}} keys %{$handlers});
        confess sprintf("No handler was found for type (%s).  Available handlers are:%s",
            $type, $available_handlers);
    }
}

sub _load_type_handlers {
    my $self = shift;

    my %handlers;
    for my $handler ($self->type_handlers) {
        my $type = $handler->type;
        if (!exists($handlers{$type})) {
            $handlers{$type} = $handler;
        } else {
            confess sprintf("Attempted to register two handlers for type (%s): %s",
                $type, join("\n", $handlers{$type}, $handler));
        }
    }
    return \%handlers;
}
Memoize::memoize('_load_type_handlers');

1;
sub echo {
    my ($self, $url) = @_;
    my ($type, $args) = _split_path($url->path);
    return File::Spec->join('', @$args);
}
