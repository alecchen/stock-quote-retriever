#---------------------------------------------------------------------------
#  gui
#---------------------------------------------------------------------------

package MyFrame;
use Wx qw(:everything);
use Wx::Event qw(:everything);
use base 'Wx::Frame';

use Mouse;
use threads;
use Yahoo::TW::Stock;
use Spreadsheet::ParseExcel;
use Smart::Comments;
use IO::All;

use version; our $VERSION = qv('0.0.1');

our %text;
$ENV{OS} eq 'Windows_NT' ? require 'lang/cht_big5.pm' : require 'lang/cht_utf8.pm';
my $encoding = $text{encoding};

has 'input'   => ( is => 'rw', isa => 'Str' );
has 'output'  => ( is => 'rw', isa => 'Str' );
has 'id_list' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub new {
    my ($class, %args) = @_;
    my $title = sprintf "%s%s", $text{name}, $VERSION->normal;

    my $self = $class->SUPER::new(
        undef, -1, $title,
        [200,200], [700,350],
        wxDEFAULT_FRAME_STYLE|wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN,
    );

    Wx::InitAllImageHandlers();

    # menu
    my $menubar  = Wx::MenuBar->new;

    my $file = Wx::Menu->new;
    $file->Append( wxID_EXIT, "$text{exit}(&E)" );

    my $option = Wx::Menu->new;
    $option->Append( wxID_SETUP, "$text{setup}(&S)" );

    my $help = Wx::Menu->new;
    $help->Append( wxID_ABOUT, "$text{about}(&A)" );

    $menubar->Append( $file,   "$text{file}(&F)" );
    $menubar->Append( $option, "$text{option}(&O)" );
    $menubar->Append( $help,   "$text{help}(&H)" );

    $self->SetMenuBar( $menubar );

    EVT_MENU( $self, wxID_ABOUT, \&on_about );
    #EVT_MENU( $self, wxID_SETUP, \&on_setup );
    EVT_MENU( $self, wxID_EXIT, sub { $self->Close } );

    # split window
    my $split = Wx::SplitterWindow->new(
        $self, -1, wxDefaultPosition, wxDefaultSize,
        wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN,
    );

    my $text = Wx::TextCtrl->new(
        $split, -1, q{},
        wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY|wxTE_MULTILINE|wxNO_FULL_REPAINT_ON_RESIZE,
    );

    my $log = Wx::LogTextCtrl->new($text);
    Wx::Log::SetActiveTarget($log);

    my $panel = Wx::Panel->new($split, -1);

    # buttons
    my $run_btn  = Wx::Button->new( $panel, -1, $text{exec}, [520,5] );
    my $exit_btn = Wx::Button->new( $panel, -1, $text{exit}, [610,5] );

    EVT_BUTTON( $self, $run_btn,  \&on_run);
    EVT_BUTTON( $self, $exit_btn, sub { $self->Close() } );

    $split->SplitHorizontally( $text, $panel, 255 );

    # misc
    $self->SetIcon( Wx::GetWxPerlIcon() );
    Wx::LogMessage(sprintf "%s%s%s!", $text{greeting}, $text{name}, $VERSION->normal);

    # temp
    $self->input('data/bobson_stock.xls');
    $self->output('data/stock.txt');


    return $self;
}

sub on_run {
    my $self = shift;

    Wx::LogMessage("$text{exec}$text{ing}...");
    Wx::LogMessage("%s = %s", $text{input}, $self->input);
    Wx::LogMessage("$text{analyze}Excel...");

	my $thr = threads->create( sub { 
		$self->parse_excel;
		$self->retrieve_quote;
	} );

	if ( $ENV{OS} ne 'Windows_NT' ) {
		$thr->join;
	}

	# <Problem>
	# ubuntu:
	# 1. without use threads, it will get stuck until parse and retrieve finished
	# 2. use threads and join will get the same result
	# 3. use threads but not join sometimes can't show full message on log window

	# windows:
	# 1. looks fine even without threads, but can't move window when exec
	# 2. use threads and join will hang up

    return;
}

sub retrieve_quote {
    my $self = shift;
    my $output = $self->output;
    unlink $output if -e $output;
    "$text{label}\n" >> io($output);
    Wx::LogMessage($text{label});

    my $agent = Yahoo::TW::Stock->new( encoding => $encoding );
    my @id_list = @{$self->id_list};
	### @id_list

    foreach my $id (@id_list) {
        my @data = $agent->fetch($id);
		# use sprintf for format command instead
		my $data = join q{ }, @data;
        "$data\n" >> io($output);
        Wx::LogMessage($data);
    }

    Wx::LogMessage("%s = %s", $text{output}, $self->output);
    Wx::LogMessage("$text{retrieve}$text{done}!");
}

sub parse_excel {
    my $self = shift;

    my @id_list;
    my $input = $self->input;

    my $excel = Spreadsheet::ParseExcel::Workbook->Parse($input);
    my $sheet = $excel->{Worksheet}->[0];

    my $row = 1;
    while (1) {
        my $cell = $sheet->{Cells}[$row][0];
        last unless $cell;
        last if $row > 1000; # need better fool proof
        my $id = $cell->{Val};
        push @id_list, $id;
        $row++;
    }

    $self->id_list(\@id_list);
    Wx::LogMessage("$text{analyze}$text{done}!");
}

sub on_about {   
    my $self = shift;
    my $info = Wx::AboutDialogInfo->new;
    $info->SetName($text{name});
    $info->SetVersion($VERSION->normal);
    $info->SetDescription($text{desc});
    $info->SetCopyright('Copyright (c) 2008 Alec Chen');
    $info->AddDeveloper('Alec Chen <alec@cpan.org>');
    $info->AddArtist('Alec Chen <alec@cpan.org>');
    Wx::AboutBox($info);
    return;
}

#---------------------------------------------------------------------------
#  main
#---------------------------------------------------------------------------

package main;

my $app = Wx::SimpleApp->new;
my $frame = MyFrame->new;
$frame->Show;
$app->MainLoop;
