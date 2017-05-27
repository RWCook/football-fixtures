package Parse_Data;
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(parse_data parse_fixtures);
use strict;
use warnings;
use lib 'lib/Fixtures';
use Cwd qw(cwd);
use Carp;
use HTML::TreeBuilder;
use File::Copy qw(cp);
use DB_SQLite;
use Config::Simple;

my $cfg=Config::Simple->new(cwd . "/football_fixtures.cfg");

sub parse_fixtures {
my $file=shift;
my $record;
my %data;
my $tree = HTML::TreeBuilder->new;
$tree->parse_file($file);

my @fixtures=$tree->look_down('_tag'=>'div', 'class'=>"fixtures-table full-table-medium");
for my $fixtures (@fixtures) {
            my @descendants=$fixtures->descendants;
            foreach my $descendant (@descendants) {
                if ($descendant->tag eq "h2" ) {
                    $data{date}=$descendant->as_trimmed_text;
            }
                if ($descendant->tag eq "th" && $descendant->attr('class') eq 'competition-title') {
                $data{competition}=$descendant->as_trimmed_text;
            }   
                if ($descendant->tag eq 'span' && ($descendant->attr('class') // "") eq 'team-home teams') {
                        $data{home_team}=$descendant->as_trimmed_text;
                }
                if ($descendant->tag eq 'span' && ($descendant->attr('class') //"") eq 'team-away teams') {
                        $data{away_team}=$descendant->as_trimmed_text;
                }
                if ($descendant->tag eq 'span' && ($descendant->attr('class') //"") eq 'score') {
                        $data{score}=$descendant->as_trimmed_text;
                }
                if ($descendant->tag eq 'td' && ($descendant->attr('class') // "") eq 'kickoff') {
                        $data{kick_off}=$descendant->as_trimmed_text;
                    push(@{$record},{%data});
                    $data{score}=undef;
                    $data{kick_off}=undef;
                    $data{home_team}=undef;
                    $data{away_team}=undef;
                    #Keep the date and competition - clear down everything else
                }
        
        } #end foreach descendants


    }
return $record;
}

sub check_files_exist {
my $files_exist=1;
my @files=qw(premier_league_table_file championship_table_file 
league_one_table_file league_two_table_file fixtures_file);

foreach my $file (@files) {
    if (!-e (cwd . $cfg->param("files." . $file)) ) {
    $files_exist=0;
    }
}
return $files_exist;
}


sub parse_data {
my $parent_dialog=shift;
my $files_exist=check_files_exist;
if ($files_exist==0) {
    IUP->Message("Error - No Data","Please get data before trying to parse it.");
    return;
}

drop_fixtures;
drop_positions;
create_fixtures;
create_positions;
my $fixture_record=parse_fixtures(cwd . $cfg->param('files.fixtures_file'));
insert_fixtures($fixture_record);
my %plt=parse_league_table(cwd . $cfg->param('files.premier_league_table_file'));
my %clt=parse_league_table(cwd . $cfg->param('files.championship_table_file'));
my %l1t=parse_league_table(cwd . $cfg->param('files.league_one_table_file'));
my %l2t=parse_league_table(cwd . $cfg->param('files.league_two_table_file'));
#my %all_tables=(%plt, %clt, %l1t, %l2t);
insert_positions(\%plt,'Premier League');
insert_positions(\%clt,'Championship');
insert_positions(\%l1t,'League 1');
insert_positions(\%l2t,'League 2');


my $messagedlg = IUP::MessageDlg->new( BUTTONS=>"OK",
                        PARENTDIALOG => $parent_dialog,
                        TITLE => "Data Parsed",
                        VALUE=>"Parsing completed.");



$messagedlg->Popup();

}


sub parse_league_table {
my $file=shift;
my $record;
my %data;
my $tree=HTML::TreeBuilder->new;
$tree->parse_file($file);
my $table=$tree->look_down(_tag=>'table', class=>'table-stats');
my @rows=$table->look_down(_tag=>'tr');
    foreach my $row (@rows) {
        my $team=$row->look_down(_tag=>'td',class=>'team-name');
        my $position=$row->look_down(_tag=>'span',class=>'position-number');
            $data{$team->as_trimmed_text}=$position->as_trimmed_text if defined $position;
    }

return %data;
}


1;
