package Result::Output;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;


class Result::Output {
    data_source => 'Genome::DataSource::GMSchema',
    schema_name => 'GMSchema',
    table_name => 'experimental.result_output',

    id_generator => '-uuid',

    id_by => [
        id => {
            is => 'Text',
            len => 32,
        },
    ],

    has => [
        result_id => {
            is => 'Text',
            len => 32,
        },
        name => {
            is => 'Text',
            len => 255,
        },

        value_class => {
            is => 'UR::Object::Type',
            id_by => 'value_class_name',
        },
        value_id => {
            is => 'VARCHAR2',
            len => 1024,
        },
        value => {
            is => 'UR::Object',
            id_by => 'value_id',
            id_class_by => 'value_class_name',
        },
    ],
};


1;
