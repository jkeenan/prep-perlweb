# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump qw( dd pp );
use Carp;
use Cwd;
use File::Copy;
use Getopt::Long;

my ($repodir);
GetOptions(
    "repo=s"        => \$repodir,
);

croak "Cannot locate top-level of checkout of 'perlweb'"
    unless (-d $repodir);
my $newsdir = "$repodir/docs/dev/perl5/news";
croak "Could not locate '$newsdir'" unless (-d $newsdir);

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
my $thisdir = cwd();
my $indir = "$thisdir/inputs";
croak "Could not locate '$indir'" unless (-d $indir);
my $outdir = "$thisdir/outputs";
croak "Could not locate '$outdir'" unless (-d $outdir);

my $pvn = "$thisdir/production-versions-needed.txt";
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
    move_to_perlweb($v, $year);
}
close $IN or croak "Unable to close after reading";
my $insertion_file = "$thisdir/insert-into-index.html";
open my $OUT, '>', $insertion_file or croak "Unable to open for writing";
for my $r ( sort { $b cmp $a  } keys %releases ) {
    say $OUT $releases{$r};
}
close $OUT or croak "Unable to close after writing";
# Then manually insert insert-into-index.html into
# /home/jkeenan/gitwork/perlweb/docs/dev/perl5/news/index.html.


sub move_to_perlweb {
    my ($v, $year) = @_;
    say STDERR join ('|' => $v, $year);
    my $html = "$outdir/perl-${v}.html";
    croak "Could not locate $html prior to copying" unless (-f $html);
    my $yeardir = "$newsdir/$year";
    croak "Could not locate $yeardir prior to copying" unless (-d $yeardir);
    copy($html => $yeardir)
        or croak "Unable to copy $html into $yeardir";
}
