package HasParam;
use Tool;
use warnings FATAL => 'all';

has_param 'p1';


__PACKAGE__->meta->make_immutable;
