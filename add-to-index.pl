# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump qw( dd pp );
use Carp;
use Cwd;

=pod

    <li>
        <a href="2012/perl-5.16.2.html">Perl 5.16.2 Released</a> -- (Nov 1, 2012)<br>
    </li>

=cut

my %months = (
    '01'    => 'Jan',
    '02'    => 'Feb',
    '03'    => 'Mar',
    '04'    => 'Apr',
    '05'    => 'May',
    '06'    => 'Jun',
    '07'    => 'Jul',
    '08'    => 'Aug',
    '09'    => 'Sep',
    '10'    => 'Oct',
    '11'    => 'Nov',
    '12'    => 'Dec',
);
my $cwd = cwd();
my $pvn = "$cwd/production-versions-needed.txt";
my %releases;
open my $IN, '<', $pvn or croak "Unable to open for reading";
while (my $r = <$IN>) {
	chomp $r;
    my ($version, $date) = split(/\t/, $r);
    next unless $date =~ m/^(\d{4})-(\d\d)-(\d\d)$/;
    my ($year, $month, $day) = ($1,$2,$3);
    my $d = 0+$day;
    my $v = $version =~ s/^v//r;
    my $li = <<END_OF_ITEM;
    <li>
        <a href="$year/perl-${v}.html">Perl $v Released</a> -- ($months{$month} $d, $year)<br>
    </li>

END_OF_ITEM
    $releases{$v} = $li;
}
close $IN or croak "Unable to close after reading";
my $insertion_file = "$cwd/insert-into-index.html";
open my $OUT, '>', $insertion_file or croak "Unable to open for writing";
for my $r ( sort { $b cmp $a  } keys %releases ) {
    say $OUT $releases{$r};
}
close $OUT or croak "Unable to close after writing";
