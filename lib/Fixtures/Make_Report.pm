package Make_Report;
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(make_report _pad_team);

use strict;
use warnings;
use IUP;
use DB_SQLite;
use Make_Report;
use PDF::API2;
use Cwd;
use Config::Simple;

my $cfg=Config::Simple->new(cwd . "/football_fixtures.cfg");

sub make_report {
my @report_params=@_;

    my $start_line=730;
    $start_line=set_up_pdf_file("fixtures.pdf",$start_line);
    my $page_number=1;

for my $i(0..$#report_params) {
    my $results;
    if ($report_params[$i]->{filter} eq 'Y') {
    $results=select_filtered_report_data($report_params[$i]->{competition},$report_params[$i]->{date});}
    else {
    $results=select_report_data($report_params[$i]->{competition},$report_params[$i]->{date});
    }

    ($page_number,$start_line)=make_pdf($results,\@report_params,$page_number,$start_line,$i);
    
    }

    if ($cfg->param("pdf.viewer") eq "DEFAULT") {
    system( cwd . "/fixtures.pdf");
    }
    else {
    system($cfg->param("pdf.viewer") . " " . cwd . "/fixtures.pdf");
    }

}

sub make_pdf {
my ($results,$params,$report_page_number,$report_current_line,$report_number)=@_;

my $pdf_file='fixtures.pdf';
my $pdf=PDF::API2->open($pdf_file);
my $linenum=$report_current_line;


my $page = $pdf->openpage($report_page_number);
my $font=$pdf->corefont('Courier');
my $fontsize=12;
my $datefont=$pdf->corefont('Verdana-Bold');
my $datefontsize=12;
my $leaguefont=$pdf->corefont('Verdana-Bold');
my $leaguefontsize=12;
my $margin=20;

$linenum-=$fontsize;
my $text=$page->text();
$text->font($font,$fontsize);
$text->translate($margin,$linenum);

for my $i(0..$#{$results}) {
if ($linenum <=30) {
    $report_page_number++;
    $pdf->page();
    $page=$pdf->openpage($report_page_number);
    $linenum =730;
    $text=$page->text();
    $text->font($font,$fontsize);
    $text->translate($margin,$linenum);
}
my %fixture_data;
$text->translate($margin,$linenum);
$fixture_data{competition}=$results->[$i]->[0];
$fixture_data{match_date}=$results->[$i]->[1];
$fixture_data{home_team}=$results->[$i]->[3];
$fixture_data{home_team_position}=$results->[$i]->[5];
$fixture_data{away_team}=$results->[$i]->[6];
$fixture_data{away_team_position}=$results->[$i]->[8];

if ($i==0 && $params->[$report_number]->{include_date} eq 'Y') {
    $text->font($datefont,$datefontsize);
    $text->text($fixture_data{match_date});
    $linenum-=$datefontsize *2;
    $text->translate($margin,$linenum);
}

if ($i==0) {
    $text->font($leaguefont,$leaguefontsize);
    $text->text($fixture_data{competition});
    $linenum-=$leaguefontsize;
    $text->translate($margin,$linenum);
}

$text->font($font,$fontsize);
my $home_team=_pad_team($fixture_data{home_team},$fixture_data{home_team_position},30);
$text->text($home_team);
$text->text(" v ");
my $away_team=_pad_team($fixture_data{away_team},$fixture_data{away_team_position},30);
$text->text($away_team);
$text->text("\t" . $results->[$i]->[2]);
$linenum-=$fontsize;
}

$pdf->update;
return ($report_page_number,$linenum);
}

sub _pad_team {
my ($text,$additional_text,$pad_length)=@_;
if (defined($additional_text)) {
    $text.=" ($additional_text)";
}

my $return=sprintf("%-" . $pad_length . "s",$text);
return $return;
}

sub set_up_pdf_file {
my ($pdf_file,$start_line)=@_;
my $pdf=PDF::API2->new;
my $page=$pdf->page();
$page->mediabox('Letter');

my $font=$pdf->corefont('Verdana', -bold =>1);
my $fontsize=16;
my $margin=20;

my $text=$page->text();
$text->font($font,$fontsize);
$text->translate($margin,$start_line);
$text->text("Football Fixtures");

$pdf->saveas($pdf_file);
$start_line-=$fontsize;
return $start_line;
}


1;
