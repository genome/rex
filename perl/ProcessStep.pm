package ProcessStep;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;


class ProcessStep {
    table_name => 'experimental.process_step',
    schema_name => 'GMSchema',
    data_source => 'Genome::DataSource::GMSchema',

    id_by => [
        process_id => {
            is => 'Text',
            len => 36,
        },
        result_id => {
            is => 'Text',
            len => 36,
        },
    ],

    has => [
        label => {
            is => 'Text',
            len => 4096,
        },
    ],

    has_optional => [
        process => {
            is => 'Process',
            id_by => 'process_id',
        },
        result => {
            is => 'Result',
            id_by => 'result_id',
        },
    ],
};


1;
