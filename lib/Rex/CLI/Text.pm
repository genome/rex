package Rex::CLI::Text;

use Moose::Role;
use warnings FATAL => 'all';

use List::Util qw(max);

sub justify {
    my ($string, $kind, $field_width, $fill, $spacer) = @_;
    $fill = $fill || " ";
    $spacer = " " unless defined($spacer);

    confess if !defined($field_width);
    confess if !defined($string);
    $field_width = max($field_width, width($string));

    my $add_left = "$fill"x$field_width . $spacer;
    my $add_right = $spacer . "$fill"x$field_width;
    my $add_width = length($add_left);

    my $num_spaces_needed = $field_width - width($string);
    my $left_index;
    if ($kind eq 'left') {
        $left_index = $add_width;
    } elsif ($kind eq 'right') {
        $left_index = $add_width - $num_spaces_needed;
    } elsif ($kind eq 'center') {
        $left_index = $add_width - floor($num_spaces_needed/2);
    } else {
        carp::croak("kind argument must be one of 'left',".
                    " 'right', or 'center', not '$kind'");
    }

    my $full_string = $add_left . $string . $add_right;

    my $color_spaces = length($string) - width($string);
    return substr($full_string, $left_index, $field_width + $color_spaces);
}

# return the VISIBLE width of the of a string.
sub width {
    my ($string) = @_;
    $string = strip_color($string);
    my @lines = split(/\n/, $string);

    my $width = length($string);
    if(scalar(@lines)) {
        $width = max(map {length($_ . '')} @lines);
    }
    return $width;
}

sub strip_color {
    my ($string) = @_;
    $string =~ s/\e\[[\d;]*[a-zA-Z]//g;
    return $string;
}

1;
