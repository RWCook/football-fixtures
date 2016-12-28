package DB_SQLite;
require Exporter;
@ISA=qw(Exporter);
@EXPORT=qw( 
drop_fixtures
drop_positions
create_positions
create_fixtures
insert_positions
insert_fixtures 
select_distinct_competitions 
select_distinct_dates 
select_report_data
select_filtered_report_data
select_table_count
);
use Cwd qw(cwd);
use DBI;
use Config::Simple;
use strict;
use warnings;

my $cfg=Config::Simple->new(cwd . "/football_fixtures.cfg");

my $dbh= DBI->connect("dbi:SQLite:dbname=:memory:" ,"","",
    {AutoCommit => 0}) or die "Can't connect";

sub select_table_count {
my $sql="select count(*) as table_count from sqlite_master where type='table'";
my $sth=$dbh->prepare($sql);
$sth->execute();
my $results=$sth->fetchrow_hashref;
return $results->{table_count};

}

sub drop_fixtures {
my $sql='drop table if exists fixtures';
my $sth=$dbh->prepare($sql);
$sth->execute;
}

sub drop_positions {
my $sql='drop table if exists positions';
my $sth=$dbh->prepare($sql);
$sth->execute;
}

sub create_positions {
my $sql='create table positions (
id integer not null primary key autoincrement,
team text(120),
position integer,
league text(60)
)';

my $sth=$dbh->prepare($sql);
$sth->execute;
}
sub create_fixtures {
my $sql='
create table fixtures(
id integer not null primary key autoincrement,
match_date text(80),
competition text(120),
home_team text(120),
away_team text(120),
kick_off text(10),
score text(10)
)';

my $sth=$dbh->prepare($sql);
$sth->execute;
}

sub insert_positions {
my ($pos,$league) =@_;
my %pos=%{$pos};
my @keys=keys %pos;
foreach my $key (@keys) {
    my $sql="insert into positions (
                    id,team,position,league)
                    values 
                    (NULL,?,?,?)";
    my $sth=$dbh->prepare($sql);
    $sth->bind_param(1,$key);
    $sth->bind_param(2,$pos{$key});
    $sth->bind_param(3,$league);
   $sth->execute;
}

    $dbh->commit or die $dbh->errstr;

}

sub insert_fixtures {
my $data=shift;
    for my $i (0..$#{$data} ) {
    my $sql="Insert into fixtures (
            id, competition,home_team,away_team,match_date,kick_off,score)
            values (
            null,?,?,?,?,?,?)";

    my $sth=$dbh->prepare($sql);
    $sth->bind_param(1,$data->[$i]->{competition});
    $sth->bind_param(2,$data->[$i]->{home_team});
    $sth->bind_param(3,$data->[$i]->{away_team});
    $sth->bind_param(4,$data->[$i]->{date});
    $sth->bind_param(5,$data->[$i]->{kick_off});
    $sth->bind_param(6,$data->[$i]->{score});
    $sth->execute;

    }
    $dbh->commit or die $dbh->errstr;
}

sub select_filtered_report_data {
my ($competition,$date)=@_;
my @filter_teams=$cfg->param('filter.filter_content');


my $sql="
select  f.competition,
        f.match_date,
        f.kick_off,
        f.home_team,
        ph.league,
        ph.position,
        f.away_team,
        pa.league,
        pa.position,
        f.score
from fixtures f
         left outer join positions pa on f.away_team=pa.team
         left outer join positions ph on f.home_team=ph.team
where f.competition=?
and f.match_date=?
and (f.home_team in (" . '?,' x scalar(@filter_teams) . ") 
or f.away_team in (" . '?,' x scalar(@filter_teams) . ") 
)";

$sql=~s/,\)/\)/g;

my $sth=$dbh->prepare($sql);
$sth->execute($competition,$date,@filter_teams,@filter_teams);
my $results=$sth->fetchall_arrayref;
return $results;
}

sub select_report_data {
my ($competition,$date)=@_;

my $sql="
select  f.competition,
        f.match_date,
        f.kick_off,
        f.home_team,
        ph.league,
        ph.position,
        f.away_team,
        pa.league,
        pa.position,
        f.score
from fixtures f
         left outer join positions pa on f.away_team=pa.team
         left outer join positions ph on f.home_team=ph.team
where f.match_date=?
and f.competition=?";


my $sth=$dbh->prepare($sql);
$sth->bind_param(1,$date);
$sth->bind_param(2,$competition);
$sth->execute;;
my $results=$sth->fetchall_arrayref;
return $results;
}

sub select_distinct_competitions {
my $sql="
select distinct competition
from fixtures
where competition is not null
order by competition asc";

my $sth=$dbh->prepare($sql);
$sth->execute;
my $results=$sth->fetchall_arrayref;
return $results;
}

sub select_distinct_dates {
my $sql="
select distinct match_date
from fixtures";

my $sth=$dbh->prepare($sql);
$sth->execute;
my $results=$sth->fetchall_arrayref;
return $results;
}

1;
