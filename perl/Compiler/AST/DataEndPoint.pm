package Compiler::AST::DataEndPoint;

use Moose;
use warnings FATAL => 'all';

has 'node' => (
    is => 'ro',
    isa => 'Compiler::AST::Node',
    required => 1,
);
has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'tags' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 1,
);
has 'is_used' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

sub update_tags {
    my ($self, $tags) = @_;

    my $new_tags = Set::Scalar->new(@$tags);
    my $old_tags = Set::Scalar->new(@{$self->tags});

    my $unioned_tags = $new_tags + $old_tags;

    $self->tags(@{$unioned_tags->members});
    return;
}

1;
