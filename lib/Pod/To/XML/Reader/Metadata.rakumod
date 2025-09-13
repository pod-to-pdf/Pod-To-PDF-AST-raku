unit role Pod::To::XML::Reader::Metadata;

has Str %!metadata;
has Str %.info is built;

my subset MetaType of Str where 'title'|'subtitle'|'author'|'name'|'version';

method !build-metadata-title {
    my @title = $_ with %!metadata<title>;
    with %!metadata<name> {
        @title.push: '-' if @title;
        @title.push: $_;
    }
    @title.push: 'v' ~ $_ with %!metadata<version>;
    @title.join: ' ';
}

method set-metadata(MetaType $key, $value) {

    %!metadata{$key.lc} = $value;

    my Str:D $info-key = do given $key {
        when 'title'|'version'|'name' { 'Title' }
        when 'subtitle' { 'Subject' }
        when 'author' { 'Author' }
    }

    my $pdf-value = $info-key eq 'Title'
        ?? self!build-metadata-title()
        !! $value;

    %!info{$info-key} = $pdf-value;
    $info-key => $pdf-value;
}

multi method metadata { %!metadata }
multi method metadata(MetaType $t) is rw {
    Proxy.new(
        FETCH => { %!metadata{$t} },
        STORE => -> $, Str:D() $v {
            self.set-metadata($t, $v);
        }
    )
}
