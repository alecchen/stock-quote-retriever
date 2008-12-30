#!/usr/bin/perl 
#===============================================================================
#       AUTHOR:  Alec Chen (alec@cpan.org)
#      VERSION:  1.0
#===============================================================================

use strict;
use warnings;
use Yahoo::TW::Stock;
use Spreadsheet::ParseExcel;
use Smart::Comments;
use IO::All;
use Encode qw(encode decode);
use Data::TreeDumper;

my $input  = 'stock.xls';
my $output = 'stock.txt';
my $encoding = 'big5';
unlink $output if -e $output;
### need a warning message

### parsing
my $excel = Spreadsheet::ParseExcel::Workbook->Parse($input);
my @id_list;
my $sheet = $excel->{Worksheet}->[0];

### collect id
my $row = 1;
while (1) {
	my $cell = $sheet->{Cells}[$row][0];
	last unless $cell;
	last if $row > 1000;
	my $id = $cell->{Val};
	push @id_list, $id;
	$row++;
}

### fetch
my $q = Yahoo::TW::Stock->new;
$q->encoding($encoding);

my @keys = qw(股票代號 股票名稱 資料日期 時間 成交 買進 賣出 漲跌 張數 昨收 開盤 最高 最低);
if ($encoding eq 'utf8') {
    @keys = map { encode('utf8', decode('big5', $_)) } @keys;
}

my $label = join q{ }, @keys;
print "$label\n";
"$label\n" >> io($output);

foreach my $id (@id_list) {
	my $result = $q->fetch($id);
	my @values = map { $result->{$_} } @keys;
	my $content = join q{ }, @values;
	print "$content\n";
    "$content\n" >> io($output);
}
