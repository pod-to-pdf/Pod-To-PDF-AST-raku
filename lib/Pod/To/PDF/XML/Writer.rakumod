unit class Pod::To::PDF::XML::Writer;

use LibXML::Writer;
use LibXML::Writer::File;
has LibXML::Writer:D $.doc = LibXML::Writer::File.new;
has Str:D @!tags;
has Str:D $.lang = 'en';
has Str  $.dtd = 'http://pdf-raku.github.io/dtd/tagged-pdf.dtd';
has Bool:D $!inlining = False;
has Bool $.verbose;
has %.replace;

enum Tags ( :Artifact<Artifact>, :Caption<Caption>, :CODE<Code>, :Document<Document>, :Header<H>, :Label<Lbl>, :LIST<L>, :ListBody<LBody>, :ListItem<LI>, :Note<Note>, :Reference<Reference>, :Paragraph<P>, :Quote<Quote>, :Span<Span>, :Section<Sect>, :Table<Table>, :TableBody<TBody>, :TableHead<THead>, :TableHeader<TH>, :TableData<TD>, :TableRow<TR>, :Link<Link>, :Emphasis<Em>, :Strong<Strong> );

method render($pod) {
    $!doc.setIndentString('  ');
    $!doc.startDocument;
    $!doc.writeDTD(Document, :system-id($!dtd));
    $!doc.setIndented(True);
    $!doc.writeText("\n");
    self!tag: Document, :Lang($!lang), {
        $.pod2pdf-xml($pod);
    }
    $!doc.endDocument;
}

method !nest-list(@lists, $level) {
    while @lists && @lists.tail > $level {
        self!close-tag(LIST);
        @lists.pop;
    }
    if $level && (!@lists || @lists.tail < $level) {
        self!open-tag(LIST);
        @lists.push: $level;
    }
}

multi method pod2pdf-xml(Pod::Block::Named $pod) {
    given $pod.name {
        when 'pod'|'para' {
            $.pod2pdf-xml: $pod.contents;
       }
        default {
            warn "ignoring {.raku} block";
            $.pod2pdf-xml($pod.contents);
        }
    }
}
multi method pod2pdf-xml(Pod::Block::Para $pod) {
    self!tag: Paragraph, {
        $.pod2pdf-xml($pod.contents);
    }
}

has %!replacing;
method !replace(Pod::FormattingCode $pod where .type eq 'R', &continue) {
    my $place-holder = $.pod2text($pod.contents);

    die "unable to recursively replace R\<$place-holder\>"
         if %!replacing{$place-holder}++;

    my $new-pod = %!replace{$place-holder};
    without $new-pod {
        note "replacement not specified for R\<$place-holder\>"
           if $!verbose;
        $_ = $pod.contents;
    }

    my $rv := &continue($new-pod);

    %!replacing{$place-holder}:delete;
    $rv;
}

multi method pod2pdf-xml(Pod::Block::Comment $pod) {
    $!doc.writeComment:  ' ' ~  $.pod2text($pod).trim ~ ' ';
}

multi method pod2pdf-xml(Pod::FormattingCode $pod) {
    given $pod.type {
        when 'B' {
            self!tag: Strong, :inline, {
                $.pod2pdf-xml($pod.contents);
            }
        }
        when 'C' {
            self!tag: CODE, :inline, {
                $.pod2pdf-xml($pod.contents);
            }
        }
        when 'T' {
            warn "todo";
            $.pod2pdf-xml($pod.contents);
        }
        when 'K' {
            warn "todo";
            $.pod2pdf-xml($pod.contents);
        }
        when 'I' {
            self!tag: Emphasis, {
                $.pod2pdf-xml($pod.contents);
            }
        }
        when 'N' {
            self!tag: Note, :inline, {
               $.pod2pdf-xml($pod.contents);
            }
        }
        when 'U' {
            self!tag, Span, :TextDecoration<Underline>, :inline, {
                $.pod2pdf-xml($pod.contents);
            }
        }
        when 'E' {
            $.pod2pdf-xml($pod.contents);
        }
        when 'Z' {
            # invisable
        }
        when 'X' {
            ...
            # otherwise X<|> ?
        }
        when 'L' {
            my $text = $.pod2text-inline($pod.contents);
            my $href = $pod.meta.head // $text;
            if $href.starts-with('#') {
                self!tag: Reference, :inline, {
                    self!tag: Link, :$href, :inline, {
                        $.pod2pdf-xml: $text;
                    }
                }
            }
            else {
                self!tag: Link, :$href, :inline, {
                    $.pod2pdf-xml: $text;
                }
            }
        }
        when 'P' {
            # todo insertion of placed text
            if $.pod2text-inline($pod.contents) -> $href {
                $.pod2pdf-xml: '(see: ';
                self!tag: Link, :$href, :inline, {
                    $.pod2pdf-xml: $href
                }
                $.pod2pdf-xml: ')';
            }
        }
        when 'R' {
            self!replace: $pod, {$.pod2pdf-xml($_)};
        }
        default {
            warn "unhandled: POD formatting code: $_\<\>";
            $.pod2pdf-xml: $pod.contents;
        }
    }
}

multi method pod2pdf-xml(Pod::Block::Code $pod) {
    self!tag: CODE, :Placement<Block>, {
        $.pod2pdf-xml: $pod.contents;
    }
}

multi method pod2pdf-xml(List:D $pod) {
    my @lists;
    for $pod.list {
        self!nest-list(@lists, .isa(Pod::Item) ?? .level !! 0);
        $.pod2pdf-xml($_);
    }
    self!nest-list(@lists, 0);
}

multi method pod2pdf-xml(Str:D $text) {
    $!inlining ||= do {
        $!doc.setIndented(False);
        True;
    }
    $!doc.writeText: $text;
}

method pod2text-inline($pod) {
    $.pod2text($pod).subst(/\s+/, ' ', :g);
}

multi method pod2text(Pod::FormattingCode $pod) {
    given $pod.type {
        when 'N'|'Z' { '' }
        when 'R' { self!replace: $pod, { $.pod2text($_) } }
        default  { $.pod2text: $pod.contents }
    }
}

multi method pod2text(Pod::Block $pod) {
    $pod.contents.map({$.pod2text($_)}).join;
}
multi method pod2text(List $pod) { $pod.map({$.pod2text($_)}).join }
multi method pod2text(Str $pod) { $pod }

method !open-tag($tag, *%atts) {
    $!doc.startElement($tag);
    $!doc.writeAttribute(.key, .value) for %atts.sort;
    @!tags.push: $tag;
}

method !close-tag(Str:D $tag where @!tags.tail ~~ $tag) {
    @!tags.pop;
    $!doc.endElement;
}

method !tag(Str:D $tag, &code, :$inline, *%atts) {
    if $inline && !$!inlining {
        $!inlining = True;
        $!doc.setIndented(False);
    }
    self!open-tag: $tag, |%atts;
    &code();
    self!close-tag: $tag;
    if !$inline && $!inlining {
        $!doc.writeText: "\n";
        $!doc.setIndented(True);
        $!inlining = False;
    }
}
