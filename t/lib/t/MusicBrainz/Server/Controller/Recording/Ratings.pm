package t::MusicBrainz::Server::Controller::Recording::Ratings;
use Test::Routine;
use Test::More;
use MusicBrainz::Server::Test qw( html_ok );

with 't::Mechanize', 't::Context';

test all => sub {

my $test = shift;
my $mech = $test->mech;
my $c    = $test->c;

$mech->get_ok('/recording/123c079d-374e-4436-9448-da92dedef3ce/ratings', 'get recording ratings');
xml_ok($mech->content);

};

1;
