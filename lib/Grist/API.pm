package Grist::API;

use strictures 2;
use v5.30;
use REST::Client;
use JSON;
use Data::Dumper;

use Moo;

=head2 Attributes

These are normal Moo attributes -- set them with `$grist->attribute("value")`, fetch them with `$grist->attribute`, pass them to the constructor as `Grist::API->new({attribute => "value"})`.

=head3 site

The site string used to access this partiuclar set of stuff.  This is the `foo`` in `https://foo.getgrist.com/`.  For your personal documents, this is "docs".  It's also the "domain" key from the `/orgs` API endpoint.

=cut

has site => ( is => 'ro', required => 1 );

=head3 debug

If true, this will dump various stuff at various points.  What stuff, what points, and if it distinguishes between different types of true values are all subject to change.  The only thing not subject to change is that it defaults to `0`.

=cut

has debug => ( is => 'rw', default => sub { 0; });

=head3 access_key

The access key you got from the Grist site.  To find this, go to http://foo.getgrist.com/ (for your value of "foo"), click on your icon/initials in the top-right corner, profile settings, and look in the "API" section.  Do not share this with anyone you do not want to do anything you can do on the grist site, and absolutely never share it publically.

=cut

has access_key => (is => 'rw');

=head3 rc_client

An instance of REST::Client with a few settings to make it more useful for us.  If you find yourself needing this (and aren't writing Grist::API itself), it means that Grist::API is incomplete, so please let me know what you needed it for by filing an issue -- see the BUGS section of this document.  Tag it "wishlist".

=cut

has rc_client => (is => 'lazy',
                  default => sub {
                      my ($self) = @_;
                      my $team = $self->team;
                       my $client = REST::Client->new(
                           host => "https://$site.getgrist.com/api",
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
