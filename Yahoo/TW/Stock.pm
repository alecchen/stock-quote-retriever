package Yahoo::TW::Stock;
use Mouse;
use Encode qw(encode decode from_to);
use WWW::Mechanize;
use HTML::TableExtract;
use Smart::Comments;
use IO::All;
use version; our $VERSION = qv('0.0.1');
use Data::TreeDumper;
use Rubyish::Attribute;

attr_accessor 'encoding';

sub fetch {
	my $self = shift;
	my $id   = shift;

	my $mech = WWW::Mechanize->new;
	$mech->get("http://tw.stock.yahoo.com/q/q?s=$id");
	my $content = $mech->content;

    my $encoding = $self->encoding || 'big5';
	$content = encode($encoding, $content);

	my $te = HTML::TableExtract->new;
	$te->parse($content);

	my @tables = $te->tables;
	my $date = [split /\s+/, $tables[4]->rows->[0]->[1]]->[1];

	my @values = @{ $tables[5]->rows->[1] }[0..10];
	my @keys   = qw(股票代號 時間 成交 買進 賣出 漲跌 張數 昨收 開盤 最高 最低);
	my $name_key = '股票名稱';
	my $date_key = '資料日期';

    if ($self->encoding eq 'utf8') {
	    @keys = map { encode('utf8', decode('big5', $_)) } @keys;
        from_to($name_key, 'big5', 'utf8');
        from_to($date_key, 'big5', 'utf8');
        
    }

	$values[0] = $id;
    $mech->get("http://tw.stock.yahoo.com/q/bc?s=$id");
    my $title = $mech->title;
	my ($name) = $title =~ /^([^(]+)/;
	$name = $self->encoding eq 'big5' ? encode ('big5', $name) : encode ('utf8', $name);

	$values[5] = sprintf "%2f", $values[2] - $values[7];
	my %result = map { $keys[$_] => $values[$_] } 0..10;

	$result{$name_key} = $name;
	$result{$date_key} = $date;

	return \%result;
}

1;
