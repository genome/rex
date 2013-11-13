package Result;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;
use Carp qw(confess);


class Result {
    table_name => 'experimental.result',
    schema_name => 'GMSchema',
    data_source => 'Genome::DataSource::GMSchema',

    id_generator => '-uuid',

    id_by => [
        id => {
            is => 'Text',
            len => 36,
        },
    ],

    has => [
        tool_class_name => {
            is => 'Text',
            len => 255,
        },
        inputs => {
            is => 'HASH',
            is_optional => 1,
            is_transient => 1,
        },
        allocation => {
            is => 'Genome::Disk::Allocation',
            id_by => 'allocation_id',
        },
    ],

    has_optional => [
        lookup_hash => {
            is => 'Text',
            len => 32
        },

        test_name => {
            is => 'Text',
            len => '255',
        },
    ],
};


1;
