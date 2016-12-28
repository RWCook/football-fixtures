package Get_Data;
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw(get_data);
use Cwd qw(cwd);
use LWP::Simple;
use Config::Simple;
use Carp;

sub get_data {
my $cfg=Config::Simple->new(cwd . "/football_fixtures.cfg");

delete_file(cwd . $cfg->param("files.fixtures_file"));
delete_file(cwd . $cfg->param("files.premier_league_table_file"));
delete_file(cwd . $cfg->param("files.championship_table_file"));
delete_file(cwd . $cfg->param("files.league_one_table_file"));
delete_file(cwd . $cfg->param("files.league_two_table_file"));

get_html_file($cfg->param("files.fixtures"),cwd . $cfg->param("files.fixtures_file"));
get_html_file($cfg->param("files.premier_league_table"),cwd . $cfg->param("files.premier_league_table_file"));
get_html_file($cfg->param("files.championship_table"),cwd . $cfg->param("files.championship_table_file"));
get_html_file($cfg->param("files.league_one_table"),cwd . $cfg->param("files.league_one_table_file"));
get_html_file($cfg->param("files.league_two_table"),cwd . $cfg->param("files.league_two_table_file"));

IUP->Message("Data Received","Data received from BBC site.");
}

sub delete_file {
my $file=shift;
if (-f $file) {
    unlink $file;
    }
    else {
    print "$file does not exist.\n";
    }

}

sub get_html_file {
my ($url,$file)=@_;

my $status=getstore($url,$file);
croak "Error getting $url (check your internet connection) " unless is_success($status);
return $status;
}


1;
