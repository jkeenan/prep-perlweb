# perl
use strict;
use warnings;
use 5.10.1;
#use Data::Dump qw( dd pp );
use Carp;
use Cwd;
use Text::Wrap qw( wrap ); $Text::Wrap::columns = 76;
use Getopt::Long;

=head1 NAME

source-to-template.pl

=head1 USAGE

    perl .../source-to-template.pl \
        --repo=/home/username/gitwork/perlweb \
        --version=5.16.3

=cut

my ($repodir, $version);
GetOptions(
    "repo=s"        => \$repodir,
    "version=s"     => \$version,
);

croak "Cannot locate top-level of checkout of 'perlweb'"
    unless (-d $repodir);
my $newsdir = "$repodir/docs/dev/perl5/news";
croak "Could not locate '$newsdir'" unless (-d $newsdir);
croak "Perl version '$version' incorrectly specified"
    unless $version =~ m/^5\.\d{2}\.\d{1,2}$/;


=head1 ASSUMPTIONS

=head2 Directory and File Structure

=head3 The checkout of the 'perlweb' repository

    .../perlweb/docs/dev/perl5/news/2012
    .../perlweb/docs/dev/perl5/news/2013
    .../perlweb/docs/dev/perl5/news/index.html
    ...

=head3 The developer's local directory

    source-to-template.pl
    inputs/
    inputs/5.16.3.source.txt
    ...
    outputs/perl-5.16.3.html

=cut

my $thisdir = cwd();
my $indir = "$thisdir/inputs";
croak "Could not locate '$indir'" unless (-d $indir);
my $outdir = "$thisdir/outputs";
croak "Could not locate '$outdir'" unless (-d $outdir);

my $input = "$indir/$version.source.txt";
croak "Could not locate input file '$input'" unless (-f $input);

=head2 Input File

The input file must be placed in F<.../inputs/>.
Its basename must be composed of the Perl 3-part version number supplied on
the command-line followed by C<.source.txt>.  Example:

    .../inputs/5.16.3.source.txt

Assumed structure of input file:  Paragraphs separated by a single linespace.
There are 3 kinds of paragraphs; each paragraph must conform to exactly one
kind.

=over 4

=item 1

Regular paragraph:  Text flush left to margin.

Examples:

    The Perl 5 development team is gratified to announce the release of
    Perl 5.16.3!

    You can find a full list of changes in the file "perldelta.pod" located in
    the "pod" directory inside the release and on the web.

=item 2

Single line with download link to metacpan.org:  May or may not be flush left
to margin.

Example:

    https://www.metacpan.org/release/RJBS/perl-5.16.3/

=item 3

SHA digests:  Each line indented 1-4 spaces from margin.  40-character SHA.  2
spaces.  Basename of tarball.

Example:

        674380237fa5a44447c6531e15bd3590d987e4b4  perl-5.16.2.tar.bz2
        9e20e38e3460ebbac895341fd70a02189d03a490  perl-5.16.2.tar.gz

=back

=cut


my @paragraphs_raw = ();
open my $IN, '<', $input or croak "Unable to open '$input' for reading";
{
    local $/ = "\n\n";
    chomp(@paragraphs_raw = <$IN>);
}
close $IN or croak "Unable to close '$input' after reading";
#dd(\@paragraphs_raw);

my @paragraphs_refined = ();
for my $p (@paragraphs_raw) {
    chomp $p;
    my %para;
    $para{raw} = $p;
    if ($p =~ m/^\s+/) {
        # the SHAs
        my @shas_raw = split(/\n/, $p);
        my @shas_refined = ();
        for my $q (@shas_raw) {
            my ($sha, $file) = $q =~ m/^\s+(\S+)\s+(\S+)$/;
            croak "Unable to parse SHA lines"
                unless (length $sha and length $file);
            my %sha_data = (
                sha     => $sha,
                file    => $file,
            );
            push @shas_refined, \%sha_data;
        }
        $para{shas} = \@shas_refined;
    }
    else {
        my $unwrapped = $p =~ s/\n/ /gr;
        if ($unwrapped =~ m/^\s*(https:\/\/www\.metacpan\.org.*)$/) {
            $para{url_raw} = $1;
        }
        else {
            $para{text} = $unwrapped;
        }
    }
    push @paragraphs_refined, \%para;
}
#dd(\@paragraphs_refined);


=head2 Output File

The output file is content for an HTML C<E<lt>bodyE<gt>E<lt>/bodyE<gt>> tag
(Template::Toolkit ??).  It will be created in
F<.../outputs/>.  Its basename will be composed of
the Perl 3-part version number supplied on the command-line followed by
C<.html>.  Example:

    .../outputs/5.16.3.html

The outputs file will be copied into the F<perlweb> repository checkout in a
later process.

=cut


my $output = "$outdir/perl-${version}.html";
open my $OUT, '>', $output or croak "Unable to open '$output' for writing";
say $OUT '[% page.title = "Perl ' . $version . ' Release Announcement" %]';
#say $OUT '<meta charset="utf-8">';
for my $p (@paragraphs_refined) {
    say $OUT '';
    if (exists $p->{url_raw}) {
        say $OUT '<p>';
        say $OUT '<a href="' . $p->{url_raw} . '">' . $p->{url_raw} . '</a>';
        say $OUT '</p>';
    }
    elsif (exists $p->{shas}) {
        say $OUT '<pre>';
        for my $el (@{$p->{shas}}) {
            say $OUT "    $el->{sha}  $el->{file}";
        }
        say $OUT '</pre>';
    }
    else {
        say $OUT '<p>';
        say $OUT wrap('','', $p->{text});
        say $OUT '</p>';
    }
}
close $OUT or croak "Unable to close '$output' after writing";
say "Finished!";
