#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More qw(no_plan);
use File::Spec::Functions qw(catfile);
use Data::Dumper;

BEGIN { use_ok('WWW::Bugzilla'); }
my $bug_number = 3033;

#my $server   = 'landfill.bugzilla.org/bugzilla-tip';
my $server   = 'landfill.bugzilla.org/bugzilla-stable';
my $email    = 'bmc@shmoo.com';
my $password = 'pileofcrap';
my $product  = 'FoodReplicator';

my $summary     = 'this is my summary';
my $description = "this is my description.\nthere are many like it, but this one is mine.";
        
my @products = ( '_test product', 'FoodReplicator', 'MyOwnBadSelf', 'Pony', 'Product with no description', "Spider S\x{e9}\x{e7}ret\x{ed}\x{f8}ns", 'WorldControl' );

my @added_comments;

if (1) {
    my $bz = WWW::Bugzilla->new(
            server   => $server,
            email    => $email,
            password => $password,
            );
    ok($bz, 'new');

    eval { $bz->available('component'); };
    like($@, qr/available\(\) needs a valid product to be specified/, 'product first');

    my @available = $bz->available('product');
    is_deeply(\@available, \@products, 'expected: product');
    
    eval { $bz->product('this is not a real product'); };
    like ($@, qr/error \: Sorry\, either the product/, 'invalid product');
   
    $bz->summary($summary);
    $bz->description($description);
    push (@added_comments, $description);
    ok($bz->product($available[1]), 'set: product');

    my $bugid = $bz->commit();
    like ($bugid, qr/^\d+$/, "bugid : $bugid");
    $bug_number = $bugid;
}

if (1)
{
    my $bz = WWW::Bugzilla->new(
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );
    
    is($bz->summary, $summary, 'summary');
    ok($bz->additional_comments("comments here"), 'add comment');
    ok($bz->commit, 'commit');
    push (@added_comments, 'comments here');
    
    ok($bz->change_status('fixed'), 'change status');
    ok($bz->commit, 'commit');
    
    ok($bz->change_status('reopen'), 'reopen');
    ok($bz->commit, 'commit');
    
    ok($bz->mark_as_duplicate(2998), 'mark as duplicate');
    ok($bz->commit, 'commit');
    push (@added_comments, "\n\n" . '*** This bug has been marked as a duplicate of <span class="bz_closed"><a href="show_bug.cgi?id=2998" title="RESOLVED DUPLICATE - This is the summary">2998</a></span> ***');
}

if (1)
{
    my $bz = WWW::Bugzilla->new(
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );
    
   
    my @comments = $bz->get_comments();
    is_deeply(\@comments, \@added_comments, 'comments');
}

if (1) {
    my $bz = WWW::Bugzilla->new(
        server   => $server,
        email    => $email,
        password => $password,
        product  => $product
    );
    ok($bz, 'new');

    is($bz->product, $product, 'new bug, with setting product');

    my %expected = (
        'component' => [
            'renamed component', 'Salt',
            'Salt II',           'SaltSprinkler',
            'SpiceDispenser',    'VoiceInterface'
        ],
        'version'  => ['1.0'],
        'platform' =>
          ['All', 'DEC', 'HP', 'Macintosh', 'PC', 'SGI', 'Sun', 'Other'],
        'os' => [
            'All',                 'Windows 3.1',
            'Windows 95',          'Windows 98',
            'Windows ME',          'Windows 2000',
            'Windows NT',          'Windows XP',
            'Windows Server 2003', 'Mac System 7',
            'Mac System 7.5',      'Mac System 7.6.1',
            'Mac System 8.0',      'Mac System 8.5',
            'Mac System 8.6',      'Mac System 9.x',
            'Mac OS X 10.0',       'Mac OS X 10.1',
            'Mac OS X 10.2',       'Linux',
            'BSD/OS',              'FreeBSD',
            'NetBSD',              'OpenBSD',
            'AIX',                 'BeOS',
            'HP-UX',               'IRIX',
            'Neutrino',            'OpenVMS',
            'OS/2',                'OSF/1',
            'Solaris',             'SunOS',
            "M\x{e1}\x{e7}\x{d8}\x{df}", 'Other'
        ]
    );

    foreach my $field (keys %expected) {
        my @available = $bz->available($field);
        is_deeply(\@available, $expected{$field}, "expected: $field");
        eval { $bz->$field($available[1]); };
        ok(!$@, "set: $field");
    }

    $bz->assigned_to($email);
    $bz->summary($summary);
    $bz->description($description);
    $bug_number = $bz->commit;
    like($bug_number, qr/^\d+$/, "bugid: $bug_number");
}

my @added_files;

if (1)
{
    my $bz = WWW::Bugzilla->new(
        server     => $server,
        email      => $email,
        password   => $password,
        bug_number => $bug_number
    );

    my $filepath = './GPL';
    {
        my $name = 'Attaching the GPL, since everyone needs a copy of the GPL!';
        my $id = $bz->add_attachment( filepath => $filepath, description => $name);
        like($id, qr/^\d+$/, 'add attachment');
        push (@added_files, { id => $id, name => $name });
    }

    SKIP: 
    {
        eval {
            my $name = 'Attaching the GPL, but as a big file!';
            my $id = $bz->add_attachment( filepath => $filepath, description => $name);
            like($id, qr/^\d+$/, 'add big attachment');
            push (@added_files, { id => $id, name => $name });
        };
        skip 'bigfile support missing in target bugzilla', 1 if ($@ && $@ =~ /Bigfile support is not available/);
        pass('attach big file');
    }
}

if (1)
{
    my $bz = WWW::Bugzilla->new(
            server     => $server,
            email      => $email,
            password   => $password,
            bug_number => $bug_number
            );
    
    use Data::Dumper;
    my @attachments = $bz->list_attachments();
 
    is_deeply(\@added_files, \@attachments, 'attached files');

    my $file = slurp('./GPL');
    is($file, $bz->get_attachment(id => $attachments[0]->{'id'}), 'get attachment by id');
    is($file, $bz->get_attachment(name => $attachments[0]->{'name'}), 'get attachment by name');
    eval { $bz->get_attachment(); };
    like ($@, qr/You must provide either the 'id' or 'name' of the attachment you wish to retreive/, 'get attachment without arguments');
}

sub slurp {
    my ($file) = @_;
    local $/;
    open (F, '<', $file) || die 'can not open file';
    return <F>;
}
