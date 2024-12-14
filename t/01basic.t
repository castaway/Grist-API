#!/usr/bin/env perl

use strictures 2;

use Test::More;
use Config::General;
use Data::Printer;

# keys.conf, or env vars:
my $keys;
if (-e 'keys.conf') {
    $keys = { Config::General->new("keys.conf")->getall() };
} elsif($ENV{GRIST_KEY} && $ENV{GRIST_SITE}) {
    $keys = {
        Keys => {
            'Grist' => {
                key => $ENV{GRIST_KEY},
                site => $ENV{GRIST_SITE},
            }
        }
    };
} else {
    die "No keys found, create keys.conf or GRIST_KEY, GRIST_SITE env vars";
}

p $keys;

use_ok('Grist::API');

my $g_api = Grist::API->new(
    site       => $keys->{Keys}{Grist}{site},
    access_key => $keys->{Keys}{Grist}{key},
    debug => 1,
);

ok($g_api, 'Loaded grist API');

# Test data names:
my $ws_name = 'API Test';
my $doc_name = 'First Document';
my $table_name = 'First_Table';

my $workspaces = $g_api->get_workspaces();
p $workspaces;

is(ref $workspaces, 'ARRAY', '->get_workspaces returns arrayref');

my ($test_workspace) = grep {$_->{name} =~ /$ws_name/} @$workspaces;
SKIP: {
    skip 'No test data', 4 if !$test_workspace;

    my ($test_doc) = grep { $_->{name} =~ /$doc_name/ } @{$test_workspace->{docs}};
    ok($test_doc, 'Found first doc');

    my $tables = $g_api->get_tables(doc => $test_doc);
    ok(scalar @$tables > 0, 'Found some tables');

    my ($test_table) = grep {$_->{id} =~ /$table_name/ } @$tables;
    ok($test_table, 'Found test table');

    my $records = $g_api->get_records(doc => $test_doc, table => $test_table);
    ok(scalar @$records > 0, 'Found table records');
};

done_testing;
