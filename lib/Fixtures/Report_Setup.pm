package Report_Setup;
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(report_setup get_report_params);

use strict;
use warnings;
use IUP;
use DB_SQLite;
use Make_Report;
use Config::Simple;
use Cwd qw(cwd);
my $cfg=Config::Simple->new(cwd . "/football_fixtures.cfg");

sub report_setup {
my $parent_dialog=shift;
my $number_of_tables=select_table_count();
if ($number_of_tables==0) {

my $messagedlg = IUP::MessageDlg->new( BUTTONS=>"OK",
                        PARENTDIALOG => $parent_dialog,
                        TITLE => "Error - No Data",
                        VALUE=>"No data. Please parse data before making a report." );



$messagedlg->Popup();
return;
}


my ($ret, $number_of_sub_reports) = IUP->GetParam(
   "Number of Sub Reports", undef,
   #define dialog controls
   "No of Sub Reports: %i[1," . $cfg->param("reports.max_subreports") . "]{Games for each competition and date combination}\n"
    ,
    #Defaults
    1
 );

   #"No of Sub Reports: %i[1,5]{Games for each competition and date combination}\n"
get_report_params($number_of_sub_reports);

}

sub get_report_params {
my $no_of_subreps=shift;
my $competitions=select_distinct_competitions();
my $dates=select_distinct_dates();

my %competitions;
    for my $i(0..$#{$competitions}) {
    $competitions{$i+1}=$competitions->[$i]->[0];
}

my %dates;
    for my $i(0..$#{$dates}) {
    $dates{$i+1}=$dates->[$i]->[0];
}


my @hbox;
my @label_competition;
my @text_competition;
my @label_date;
my @text_date;
my @label_london_only;
my @text_london_only;
my @label_include_date;
my @text_include_date;
my @list_competition;
my @list_date;
my $vbox= IUP::Vbox->new([]);
my $dlg2;
my $frame_vbox=IUP::Frame->new(
                TITLE => 'Sub Reports',
                MARGIN=>"70x80",
                );
for my $i(1..$no_of_subreps) {
$hbox[$i]=IUP::Hbox->new([]);
        
$label_competition[$i] = IUP::Label->new(
                                TITLE => 'Competition:',
                                SIZE =>50,
                                ALIGNMENT=>'ATOP',
                        );

$text_competition[$i]= IUP::Text->new(
                                VALUE => 'Whatever you want',
                                SIZE => 100,
                                ALIGNMENT=>'ABOTTOM',
                                );


$label_date[$i] = IUP::Label->new(
                                TITLE => 'Date:',
                                SIZE =>25,
                                ALIGNMENT=>'ALEFT',
                        );

$text_date[$i]= IUP::Text->new(
                                VALUE => '',
                                SIZE => 40,
                                ALIGNMENT=>'ALEFT',
                                );

$label_london_only[$i] = IUP::Label->new(
                                TITLE => $cfg->param("filter.filter_name"),
                                SIZE =>90,
                                ALIGNMENT=>'ALEFT',
                        );

$text_london_only[$i]= IUP::Toggle->new(
                                VALUE => 'Off',
                                );

$label_include_date[$i] = IUP::Label->new(
                                TITLE => 'Include Date:',
                                SIZE =>60,
                                ALIGNMENT=>'ALEFT',
                        );

$text_include_date[$i]= IUP::Toggle->new(
                                VALUE => 'Off',
                                );

$list_competition[$i] = IUP::List->new( 
            %competitions,
            DROPDOWN=>'YES',
            SORT=>'NO',
            VALUE=>0,
            #SIZE =>200, 
            );

$list_date[$i] = IUP::List->new( 
            %dates,
            DROPDOWN=>'YES', 
            #SIZE =>160, 
            );

}

my $hbox_empty_row=IUP::Hbox->new();

my $hbox_buttons=IUP::Hbox->new(
                    GAP=>30,
                    ALIGNMENT=>'ACENTER',
                    MARGIN=>180);

my $cancel_btn=IUP::Button->new(
                TITLE=>"Cancel",
                SIZE=>60,
                ACTION => sub {
                        $dlg2->Destroy();}
                );


$dlg2 = IUP::Dialog->new( TITLE=>"Report Details",
            #                SIZE => "710x260",
                            MARGIN=>"10x10",
                            child =>
                                    $vbox,
                            );

$vbox->SetAttribute(NMARGIN=>"10x50");

#Load Components
for my $x(1..$no_of_subreps) {

    $vbox->Append($hbox[$x]);
    $hbox[$x]->Map;
    $hbox[$x]->Append($label_competition[$x]);
    $label_competition[$x]->Map;
    $hbox[$x]->Append($list_competition[$x]);
    $list_competition[$x]->Map;

    $hbox[$x]->Append($label_date[$x]);
    $label_date[$x]->Map;
    $hbox[$x]->Append($list_date[$x]);
    
    $list_date[$x]->Map;

    $hbox[$x]->Append($label_london_only[$x]);
    $label_london_only[$x]->Map;
    $hbox[$x]->Append($text_london_only[$x]);
    $text_london_only[$x]->Map;

    $hbox[$x]->Append($label_include_date[$x]);
    $label_include_date[$x]->Map;
    $hbox[$x]->Append($text_include_date[$x]);
    $text_include_date[$x]->Map;

   $hbox[$x]->SetAttribute( 
                            NMARGIN => 40,
                            ALIGNMENT=>'ACENTER', #Centres widgets with hbox!
                            GAP => 10,
                            );
    }

$vbox->Append($hbox_empty_row);
$hbox_empty_row->Map;

my $ok_btn=IUP::Button->new(
                TITLE=>"Ok",
                SIZE=>60,
                ACTION => sub {
                        my @report_param;
                        my %convert_values=(
                            "ON"=>'Y',
                            "OFF"=>'N',
                            );

                        for my $i (1..$no_of_subreps) {
                        $report_param[$i-1]->{competition}=$competitions{$list_competition[$i]->GetAttribute("VALUE")};
                        $report_param[$i-1]->{date}= $dates{$list_date[$i]->GetAttribute("VALUE")};
                        $report_param[$i-1]->{include_date}= $convert_values{$text_include_date[$i]->GetAttribute("VALUE")};
                        $report_param[$i-1]->{filter}=$convert_values{$text_london_only[$i]->GetAttribute("VALUE")};
                        }
                        make_report(@report_param);
                        $dlg2->Destroy();}
                );
$vbox->Append($hbox_buttons);
$hbox_buttons->Map;
$hbox_buttons->Append($ok_btn);
$ok_btn->Map;
$hbox_buttons->Append($cancel_btn);
$cancel_btn->Map;
#$dlg2->Show();
$dlg2->ShowXY(10,10);

}


1;
