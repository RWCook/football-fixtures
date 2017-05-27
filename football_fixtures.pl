use strict;
use warnings;
use lib 'lib';
use IUP ":all";
use Fixtures::Get_Data;
use Fixtures::Parse_Data;
use Fixtures::Report_Setup;
use Config::Simple;

my $cfg=Config::Simple->new('football_fixtures.cfg'); 

IUP->SetGlobal( "DEFAULTFONTSIZE"=>$cfg->param("format.font_size") );
my $main_dialog=IUP::Dialog->new(
        TITLE => 'Football Fixtures',
        SIZE => "200x100",
        MARGIN=> "10x10",
        );


my $vbox=IUP::Vbox->new([]);
$main_dialog->Append($vbox);
$vbox->Map;

#Get Data Make Report Preview Report Exit
my @buttons;
push(@buttons,{title=>'Get Data',action=> sub { Get_Data::get_data($main_dialog);} });
#push(@buttons,{title=>'Parse Data',action=>\&Parse_Data::parse_data});
push(@buttons,{title=>'Parse Data',action=> sub {Parse_Data::parse_data($main_dialog);} });
push(@buttons,{title=>'Make Report',action=> sub {Report_Setup::report_setup($main_dialog);} });
push(@buttons,{title=>'Exit',action=>\&cb_exit});

my @but;
for my $i(0..$#buttons) {
    $but[$i]=IUP::Button->new(
                    TITLE=>"$buttons[$i]->{title}",
                    ACTION=>$buttons[$i]->{action},
                    SIZE => 80,
                );

$vbox->Append($but[$i]);
$but[$i]->Map;
}

$main_dialog->Show;
IUP->MainLoop;

sub cb_exit {
IUP_CLOSE;
}

