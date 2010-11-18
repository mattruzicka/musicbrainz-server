package MusicBrainz::Server::Email::Subscriptions;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw( ArrayRef Str );
use MooseX::Types::Structured qw( Map );
use String::TT qw( strip tt );
use MusicBrainz::Server::Entity::Types;

has 'editor' => (
    isa => 'Editor',
    required => 1,
    is => 'ro',
);

with 'MusicBrainz::Server::Email::Role';

has '+to' => (
    lazy => 1,
    default => sub { shift->editor->email }
);

has '+subject' => (
    default => 'Edits for your subscriptions'
);

has 'deletes' => (
    isa => ArrayRef,
    is => 'ro',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        has_deletes => 'count',
    }
);

has 'edits' => (
    isa => Map[Str, ArrayRef],
    is => 'ro',
    default => sub { {} }
);

sub extra_headers {
    return (
        'Reply-To' => $MusicBrainz::Server::Email::SUPPORT_ADDRESS
    )
}

sub text {
    my $self = shift;
    my @sections;

    push @sections, $self->deleted_subscriptions
        if $self->has_deletes;

    push @sections, $self->edits_for_type(
        'Changes for your subscribed artists',
        @{ $self->edits->{artist} }
    ) if exists $self->edits->{artist};

    push @sections, $self->edits_for_type(
        'Changes for your subscribed labels',
        @{ $self->edits->{label} }
    ) if exists $self->edits->{label};

    return join("\n\n", @sections);
}

sub header {
    my $self = shift;
    return strip tt q{
This is a notification that edits have been added for artists, labels and
editors to whom you subscribed on the MusicBrainz web site.
To view or edit your subscription list, please use the following link:
[% server %]/user/[% self.editor.name %]/subscriptions.html

To see all open edits for your subscribed artists, see this link:
[% server %]/edit/search
};
}

sub footer {
    my $self = shift;
    return strip tt q{
Please do not reply to this message.  If you need help, please see
[% server %]/doc/ContactUs
};
}

sub edits_for_type {
    my $self = shift;
    my $header = shift;
    my $subs = \@_;
    return strip tt q{
[% header %]
--------------------------------------------------------------------------------
[% FOR sub IN subs %]
[%- artist = sub.subscription.artist -%]
[% artist.name %] ([% artist.comment %]) ([% sub.open.size %] open, [% sub.applied.size %] applied)
[% server %]/artist/[% artist.gid %]/edits
[% END %]
};
}

sub deleted_subscriptions {
    my $self = shift;
    return strip tt q{
Deleted and merged artists or labels
--------------------------------------------------------------------------------

Some of your subscribed artists or labels have been merged or deleted:

[% FOR sub IN self.deletes;
edit = sub.deleted_by_edit || sub.merged_by_edit;
type = sub.artist_id ? 'artist' : 'label';
entity_id = sub.artist_id || sub.label_id -%]
[%- type | ucfirst %] #[% entity_id %] - [% sub.deleted_by_edit ? 'deleted' : 'merged' %] by edit #[% edit %]
[% server %]/edit/[% edit %]

[% END %]
}
}

1;
