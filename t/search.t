#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 22;
use File::Spec::Functions qw(catfile);
use Data::Dumper;

BEGIN { use_ok('WWW::Bugzilla::Search'); }

#my $server   = 'landfill.bugzilla.org/bugzilla-tip';
my $server   = 'landfill.bugzilla.org/bugzilla-stable';
my $email    = 'bmc@shmoo.com';
my $password = 'pileofcrap';

my $bz = WWW::Bugzilla::Search->new(
            server   => $server,
            email    => $email,
            password => $password,
            protocol => 'https',
            );
ok($bz, 'new');
isa_ok($bz, 'WWW::Bugzilla::Search');


my %fields = (
    'classification' => ['Unclassified'],
    'product' => ["_test product", "Another Product", "DeleteMe", "FoodReplicator", "MyOwnBadSelf", "Product with no description", "Spider S\x{e9}\x{e7}ret\x{ed}\x{f8}ns", "WorldControl"],
    'component' => ["A Component", "Cleanup", "Comp1", "comp2", "Component 1", "Digestive Goo", "EconomicControl", "PoliticalBackStabbing", "renamed component", "Salt", "Salt II", "SaltSprinkler", "SpiceDispenser", "TheEnd", "Venom", "VoiceInterface", "WeatherControl", "Web"],
    'version' => ['1.0', '1.0.1.0.1', 'unspecified'],
    'target_milestone' => ['---', 'M1', "First Milestone", "Second Milestone", "Third Milestone", "Fourth Milestone", "Fifth Milestone"],
    'bug_status' => [ "UNCONFIRMED", "NEW", "ASSIGNED", "REOPENED", "RESOLVED", "VERIFIED", "CLOSED" ],
    'resolution' => [ "FIXED", "INVALID", "WONTFIX", "LATER", "REMIND", "DUPLICATE", "WORKSFORME", "MOVED", '---' ],
    'bug_severity' => ["blocker", "critical", "major", "normal", "minor", "trivial", "enhancement" ],
    'priority' => [ "P1", "P2", "P3", "P4", "P5" ],
    'rep_platform' => [ "All", "DEC", "HP", "Macintosh", "PC", "SGI", "Sun", "Other" ],
    'op_sys' => [ "All", "Windows 3.1", "Windows 95", "Windows 98", "Windows ME", "Windows 2000", "Windows NT", "Windows XP", "Windows Server 2003", "Mac System 7", "Mac System 7.5", "Mac System 7.6.1", "Mac System 8.0", "Mac System 8.5", "Mac System 8.6", "Mac System 9.x", "Mac OS X 10.0", "Mac OS X 10.1", "Mac OS X 10.2", "Linux", "BSD/OS", "FreeBSD", "NetBSD", "OpenBSD", "AIX", "BeOS", "HP-UX", "IRIX", "Neutrino", "OpenVMS", "OS/2", "OSF/1", "Solaris", "SunOS", "M\x{e1}\x{e7}\x{d8}\x{df}", "Other" ]
    );
       

foreach my $field (sort keys %fields) {
    is_deeply([$bz->$field()], $fields{$field}, $field);
}

$bz->product('FoodReplicator');
$bz->assigned_to('mybutt@inyourface.com');
$bz->reporter('bmc@shmoo.com');

my %searches = ( 'this was my summary' => [3035], 'this isnt my summary' => [3037, 3039] );
foreach my $text (sort keys %searches) {
    $bz->summary($text);
    my @bugs = $bz->search();
    is(scalar(@bugs), scalar(@{$searches{$text}}), 'search count : ' . $text);
    map(isa_ok($_, 'WWW::Bugzilla'), @bugs);
    my @bug_ids = map($_->bug_number, @bugs);
    is_deeply($searches{$text}, [@bug_ids], 'bug numbers : ' . $text);
}

$bz->reset();
is_deeply({}, $bz->{'search_keys'}, 'reset');
