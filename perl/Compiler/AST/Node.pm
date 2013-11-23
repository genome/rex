package Compiler::AST::Node;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use Compiler::AST::DataEndPoint;
use Memoize qw();

has source_path => (
    is => 'rw',
    isa => 'Str',
);
has parallel => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]},
);
has couplers => (
    is => 'rw',
    isa => 'ArrayRef[Compiler::AST::Coupler]',
    default => sub {[]},
);

has alias => (
    is => 'rw',
    isa => 'Str',
);
has inputs => (
    is => 'rw',
    isa => 'ArrayRef[Compiler::AST::DataEndPoint]',
    default => sub {[]},
);
has outputs => (
    is => 'rw',
    isa => 'ArrayRef[Compiler::AST::DataEndPoint]',
    default => sub {[]},
);
has constants => (
    is => 'rw',
    isa => 'HashRef[Value]',
    default => sub {{}},
);

sub dag {
    confess 'Abstract method!';
}

sub constant_couplers {
    my $self = shift;

    return grep {$_->is_constant} @{$self->couplers};
}

sub internal_couplers {
    my $self = shift;

    return grep {$_->is_internal} @{$self->couplers};
}


sub source_path_components {
    my $self = shift;

    my @parts = split /::/, $self->source_path;
    my @reversed_parts = reverse @parts;
    return \@reversed_parts;
}

sub unique_output {
    my ($self, $type) = @_;

    my $outputs_hash = $self->_outputs_hash;

    if (exists $outputs_hash->{$type}) {
        my %outputs_of_type = %{$outputs_hash->{$type}};

        if (scalar(keys %outputs_of_type) == 1) {
            return (values %outputs_of_type)[0];
        } else {
            confess sprintf('Node %s (%s) has more than one output of type (%s): %s',
                $self->source_path, $self->alias || '', $type, join(', ', keys %outputs_of_type),
            );
        }
    } else {
        confess sprintf('Node %s (%s) has no output with type (%s).',
            $self->source_path, $self->alias || '', $type,
        );
    }
}

sub _outputs_hash {
    my $self = shift;

    my %result;
    return \%result unless $self->outputs;

    for my $output (@{$self->outputs}) {
        $result{$output->type}{$output->name} = $output;
    }
    return \%result;
}
Memoize::memoize('_outputs_hash');

sub input_named {
    my ($self, $name) = @_;

    my $inputs_hash = $self->_inputs_hash;

    if (exists $inputs_hash->{$name}) {
        return $inputs_hash->{$name};
    } else {
        confess sprintf('Tool %s (%s) has no input with name (%s).',
            $self->source_path, $self->alias || '', $name,
        );
    }
}

sub _inputs_hash {
    my $self = shift;

    my %result;
    return \%result unless $self->inputs;

    for my $input (@{$self->inputs}) {
        $result{$input->name} = $input;
    }
    return \%result;
}
Memoize::memoize('_inputs_hash');


sub _create_data_end_point {
    my $self  = shift;

    return Compiler::AST::DataEndPoint->new(node => $self, @_);
}


1;
