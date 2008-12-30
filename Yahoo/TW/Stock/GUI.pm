package Yahoo::TW::Stock::GUI;

use Wx qw(:everything);
use Wx::Event qw(:everything);
use base 'Wx::Frame';

use Rubyish::Attribute;

#attr_accessor 'picker';

sub new {
	my $parent = shift;
	my $self = $parent->SUPER::new(undef, -1, 'test');
	my $panel = Wx::Panel->new($self, -1);

	# input
	my $input_label = Wx::StaticText->new($panel, -1, 'Input', [10,50]);
	my $input_btn   = Wx::Button->new($panel, 1, 'Browser', [100,50]);

	# output
	my $output_label = Wx::StaticText->new($panel, -1, 'Output', [10,100]);
	my $output_btn   = Wx::Button->new($panel, 1, 'Browser', [100,100]);

	# execute
	my $exe_btn = Wx::Button->new($panel, 1, 'Run', [100,150]);

	return $self;
}

1;
