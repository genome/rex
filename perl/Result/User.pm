package Result::User;

use strict;
use warnings FATAL => 'all';

use Genome;
use UR;


class Result::User {
    table_name => 'experimental.result_user',
    schema_name => 'GMSchema',
    data_source => 'Genome::DataSource::GMSchema',

    id_generator => '-uuid',

    id_by => [
        id => {
            is => 'Text',
            len => 32,
        },
    ],

    has => [
        result => {
            is => 'Result',
            id_by => 'result_id',
        },

        user_class => {
            is => 'UR::Object::Type',
            id_by => 'user_class_name',
        },
        user_id => {
            is => 'VARCHAR2',
            len => 256,
        },
        user => {
            is => 'UR::Object',
            id_by => 'user_id',
            id_class_by => 'user_class_name',
        },
    ],
};


1;
