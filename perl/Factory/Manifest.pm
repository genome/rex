package Factory::Manifest;

use strict;
use warnings FATAL => 'all';

use Manifest::Writer;
use Manifest::Reader;
use File::Basename qw();
use File::Spec qw();
use File::Find::Rule qw();


sub on_directory {
    my $dir = shift;
    my $writer = Manifest::Writer->create(
        manifest_file => File::Spec->join($dir, 'manifest.xml'));

    for my $file (File::Find::Rule->file->in($dir)) {
        if (_extension($file)) {
            $writer->add_file(path => $file,
                kilobytes => _kilobytes($file),
                tag => _extension($file));
        }
    }
    $writer->save;

    return Manifest::Reader->create(manifest_file => $writer->manifest_file);
}

sub _kilobytes {
    my $file = shift;

    my $bytes = -s $file;

    return int($bytes / 1024);
}

sub _extension {
    my $file = shift;
    my ($name, $path, $suffix) = File::Basename::fileparse($file, qr/\.[^.]*/);
    if ($suffix) {
        return substr($suffix, 1);
    } else {
        return '';
    }
}

1;
