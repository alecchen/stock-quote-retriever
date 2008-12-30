package MyFrame;
use Wx qw(:everything);
use Wx::Event qw(:everything);
use base 'Wx::Frame';

use Readonly;
use Cwd;
use Rubyish::Attribute;

use Yahoo::TW::Stock;
use Spreadsheet::ParseExcel;
use threads;
use Smart::Comments;

use version; our $VERSION = qv('0.0.1');

#require 'lang/cht_big5.pm';
require 'lang/cht_utf8.pm';

my $title = sprintf "%s%s", $text{name}, $VERSION->normal;

attr_accessor 'input', 'output';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(
        undef, -1, $title,
        [300,200], [600,350],
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

#    # file picker
#
#    my $input_label  = Wx::StaticText->new($panel, -1, 'Input',  [35,15]);
#    my $output_label = Wx::StaticText->new($panel, -1, 'Output', [20,50]);
#
#    my $input_fp = Wx::FilePickerCtrl->new(
#        $panel, -1, cwd(),
#        'Choose input file name',
#        'Excel spreadsheets (*.xls)|*.xls|All files (*.*)|*.*',
#        [70, 10], [450, 30], wxPB_USE_TEXTCTRL,
#    );
#
#    my $output_fp = Wx::FilePickerCtrl->new(
#        $panel, -1, cwd(),
#        'Choose output file name',
#        'Plain Text (*.txt)|*.txt|All files (*.*)|*.*',
#        [70, 45], [450, 30], wxPB_USE_TEXTCTRL,
#    );
#
#    EVT_FILEPICKER_CHANGED( $self, $input_fp,  \&on_input_change  );
#    EVT_FILEPICKER_CHANGED( $self, $output_fp, \&on_output_change );

    # buttons
    my $run_btn  = Wx::Button->new( $panel, -1, $text{exec}, [420,5] );
    my $exit_btn = Wx::Button->new( $panel, -1, $text{exit}, [510,5] );

    EVT_BUTTON( $self, $run_btn,  \&on_run);
    EVT_BUTTON( $self, $exit_btn, sub { $self->Close() } );

    $split->SplitHorizontally( $text, $panel, 255 );

    # misc
    $self->SetIcon( Wx::GetWxPerlIcon() );
    Wx::LogMessage(sprintf "%s%s%s!", $text{greeting}, $text{name}, $VERSION->normal);

    return $self;
}

# config menubar
sub on_input_change {
    my( $self, $event ) = @_;
    my $input = $event->GetPath;
    $self->input($input);
    Wx::LogMessage( "Input changed (%s)", $input );
}

sub on_output_change {
    my( $self, $event ) = @_;
    my $output = $event->GetPath;
    $self->output($output);
    Wx::LogMessage( "Output changed (%s)", $output );
}

sub on_run {
    my $self = shift;

    Wx::LogMessage("$text{exec}$text{ing}...");
    Wx::LogMessage("$text{analyze}Excel...");

    threads->create( sub { 
        ### parse excel
        $self->parse_excel;
    } );

    return;
}

sub parse_excel {
    my $self = shift;

    my @id_list;
    my $input  = 'data/stock.xls';
    my $output = 'data/stock.txt';

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

    ### @id_list
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

package main;

my $app = Wx::SimpleApp->new;
my $frame = MyFrame->new;
$frame->Show;
$app->MainLoop;
