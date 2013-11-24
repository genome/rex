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
    isa => 'HashRef[Compiler::AST::DataEndPoint]',
    default => sub {{}},
);
has outputs => (
    is => 'rw',
    isa => 'HashRef[Compiler::AST::DataEndPoint]',
    default => sub {{}},
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
    my ($self, $tags) = @_;

    my $outputs_hash = $self->_outputs_hash;

    my @output_name_sets;
    for my $tag (@$tags) {
        if (exists $outputs_hash->{$tag}) {
            push @output_name_sets, $outputs_hash->{$tag};
        } else {
            confess sprintf("Node %s (%s) has no output with tag (%s)",
                $self->source_path, $self->alias, $tag);
        }
    }

    my @potential_output_names = _intersection(@output_name_sets)->members;
    if (scalar(@potential_output_names) == 0) {
        confess sprintf("Node %s (%s) has no output with tags [%s]",
            $self->source_path, $self->alias, join(', ', @$tags));
    } elsif (scalar(@potential_output_names) == 1) {
        return $self->outputs->{$potential_output_names[0]};
    } else {
        confess sprintf("Node %s (%s) has more than one output with tags [%s]: %s",
            $self->source_path, $self->alias, join(', ', @$tags),
            join(', ', @potential_output_names));
    }
}

sub _intersection {
    my ($first, @rest) = @_;

    return $first->intersection(@rest);
}

sub _outputs_hash {
    my $self = shift;

    my %result;
    return \%result unless $self->outputs;

    for my $output (values %{$self->outputs}) {
        for my $tag (@{$output->tags}) {
            my $bin = $result{$tag};
            unless (defined $bin) {
                $bin = Set::Scalar->new;
                $result{$tag} = $bin;
            }
            $bin->insert($output->name);
        }
    }
    return \%result;
}
Memoize::memoize('_outputs_hash');

sub _create_data_end_point {
    my $self  = shift;

    return Compiler::AST::DataEndPoint->new(node => $self, @_);
}


1;
