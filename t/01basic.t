#!/usr/bin/env perl

use strictures 2;

use Test::More;
use Config::General;
use Data::Printer;

use_ok('Grist::API');

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

my $g_api = Grist::API->new(
    site       => $keys->{Keys}{Grist}{site},
    access_key => $keys->{Keys}{Grist}{key},
    debug => 1,
);

ok($g_api, 'Loaded grist API');

# Test data names:
my $ws_name = 'API Test';
my $doc_name = 'First Document';
# API doesnt return us the table name anywhere!?
my $table_id = $g_api->name_to_id('First Table');
my $col1_name = $g_api->name_to_id('Col 1');

my $workspaces = $g_api->get_workspaces();

is(ref $workspaces, 'ARRAY', '->get_workspaces returns arrayref');

my ($test_workspace) = grep {$_->{name} =~ /$ws_name/} @$workspaces;
SKIP: {
    skip 'No test data', 4 if !$test_workspace;

    my ($test_doc) = grep { $_->{name} =~ /$doc_name/ } @{$test_workspace->{docs}};
    ok($test_doc, 'Found first doc');

    my $tables = $g_api->get_tables(doc => $test_doc);
    ok(scalar @$tables > 0, 'Found some tables');

    my ($test_table) = grep {$_->{id} =~ /$table_id/ } @$tables;
    ok($test_table, 'Found test table');

    my $records = $g_api->get_records(doc => $test_doc, table => $test_table);
    ok(scalar @$records > 0, 'Found table records');

    my ($hello_world) = grep { $_->{$col1_name} eq 'Hello World' } @$records;
    ok($hello_world, 'Found test row');

    # Increase the numbers col value:
    my $col2 = $g_api->name_to_id('Col 2');
    $hello_world->{$col2}++;
    my $status = $g_api->update_record(doc => $test_doc, table => $test_table, record => $hello_world);
    ok($status, 'Updated numeric column');
    # refetch record to compare:
    my $new_records = $g_api->get_records(doc => $test_doc, table => $test_table);
    my ($new_hw) = grep { $_->{$col1_name} eq 'Hello World' } @$new_records;
    is($new_hw->{$col2},$hello_world->{$col2}, 'Increased col2 value');

    # Add another record:
    my $new_status = $g_api->add_record(
        doc => $test_doc,
        table => $test_table,
        record => {
            'Col_1' => 'New record',
                'Col_2' => 10,
                'Col_3' => 'true',
                'Col_4' => '', # ???
                'Col_5' => '2024-12-02',
        });
    ok($new_status, 'Added new record');
};

done_testing;
