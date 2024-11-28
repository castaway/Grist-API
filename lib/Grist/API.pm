package Grist::API;

use strictures 2;
use v5.30;
use REST::Client;
use JSON;
use Data::Dumper;

use Moo;
has debug => ( is => 'rw', default => sub { 0; });
has access_key => (is => 'rw');
has rc_client => (is => 'lazy',
                  default => sub {
                      my ($self) = @_;
                       my $client = REST::Client->new(
                           host => 'https://foolsdog.getgrist.com/api',
                           );
                       $client->addHeader('Authorization', 'Bearer '. $self->access_key);
                       $client->addHeader('Content-Type', 'application/json');
                       $client->setFollow(1);
                       push @{$client->getUseragent->requests_redirectable}, 'POST';
                       return $client;
                       
                  });
has workspaces => (is => 'rw');
has master_doc => (is => 'rw');
has tables     => (is => 'rw');
has apps       => (is => 'rw');

sub get_workspaces {
    my ($self) = @_;

    my $workspaces = decode_json($self->rc_client->GET('orgs/current/workspaces')->responseContent());
    print Dumper($workspaces) if $self->debug;
    my ($master_doc) = grep { $_->{name} =~ /Master/ } @{ $workspaces->[0]{docs} };

    $self->master_doc($master_doc);
    $self->workspaces($workspaces);
}

sub get_tables {
    my ($self) = @_;

    my $tables = decode_json($self->rc_client->GET('docs/' . $self->master_doc->{id} . '/tables')->responseContent());
    print Dumper($tables) if $self->debug;

    $self->tables($tables);
}

sub get_apps {
    my ($self) = shift;

    my $app_data = decode_json($self->rc_client->GET('docs/' . $self->master_doc->{id} . '/tables/ProductNames/records')->responseContent());
    print Dumper($app_data) if $self->debug;

    $self->apps($app_data);
}
1;

# print Dumper($app_data);
# 'fields' => {
#               'app_bundle_id' => 'com.foolsdog.soprafino',
#               'Catalog_Description' => '',
#               'Catalog_Copyright' => '',
#               'IAP_Description' => undef,
#               'Catalog_Credits' => '',
#               'Full_App_Name' => 'Soprafino Tarot',
#               'Abbreviated_App_Name' => '',
#               'IAP_Price' => undef
#             }
