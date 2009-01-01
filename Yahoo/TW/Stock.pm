package Yahoo::TW::Stock;
use Mouse;
use Encode qw(encode decode from_to);
use WWW::Mechanize;
use HTML::TableExtract;
use Smart::Comments;
use IO::All;
use Data::TreeDumper;
use Rubyish::Attribute;

use version; our $VERSION = qv('0.0.1');

has 'encoding' => ( is => 'rw', isa => 'Str', default => 'big5' );

sub fetch {
	my $self = shift;
	my $id   = shift;

	my $mech = WWW::Mechanize->new;
	$mech->get("http://tw.stock.yahoo.com/q/q?s=$id");
	my $content = $mech->content;

    my $encoding = $self->encoding;
	$content = encode($encoding, $content);

	my $te = HTML::TableExtract->new;
	$te->parse($content);

	my @tables = $te->tables;
	my $date = [split /\s+/, $tables[4]->rows->[0]->[1]]->[1];

    # raw data
	my @values = @{ $tables[5]->rows->[1] }[0..10];
	$values[5] = sprintf "%2f", $values[2] - $values[7];

    # name
    $mech->get("http://tw.stock.yahoo.com/q/bc?s=$id");
    my $title = $mech->title;
	my ($name) = $title =~ /^([^(]+)/;
	$name = $self->encoding eq 'utf8' ? encode('utf8', $name) : encode('big5', $name);
	# it's ok on windows, needs to test on ubuntu

    return ($id, $name, $date, @values[1..10]);
}

1;
