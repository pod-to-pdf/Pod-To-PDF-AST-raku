unit class Pod::To::PDF::XML::Writer;

subset Level where 0..6;

has Pair:D @!tags;
has UInt:D @!numbering;
has Str:D $.lang = 'en';
has Str  $.dtd = 'http://pdf-raku.github.io/dtd/tagged-pdf.dtd';
has $!level = 1;
has Bool $!inlining = False;
has Bool $.verbose;
has %.replace;

enum Tags ( :Artifact<Artifact>, :Caption<Caption>, :CODE<Code>, :Division<Div>, :Document<Document>, :Header<H>, :Label<Lbl>, :LIST<L>, :ListBody<LBody>, :ListItem<LI>, :FENote<FENote>, :Reference<Reference>, :Paragraph<P>, :Quote<Quote>, :Span<Span>, :Section<Sect>, :Table<Table>, :TableBody<TBody>, :TableHead<THead>, :TableHeader<TH>, :TableData<TD>, :TableRow<TR>, :Link<Link>, :Emphasis<Em>, :Strong<Strong>, :Title<Title> );

method render($pod) {
    my $ast = self!tag: Document, :Lang($!lang), {
        $.pod2pdf-xml($pod);
    }
    '#xml' => [
        ('!' ~ Document) => %( :system<http://pdf-raku.github.io/dtd/tagged-pdf.dtd> ),
        "\n",
        $ast,
    ]
}

multi method pod2pdf-xml(Pod::Block::Named $pod) {
    given $pod.name {
        when 'pod'|'para' {
            $.pod2pdf-xml: $pod.contents;
        }
        when 'TITLE'|'SUBTITLE' {
            my $tag = $_ eq 'TITLE' ?? Title !! 'H2';
            temp $!level = $_ eq 'TITLE' ?? 0 !! 1;
            self!tag: $tag, {
                $.pod2pdf-xml($pod.contents.&strip-para());
            }
        }
        default {
            temp $!level += 1;
            my $name = do if $_ eq .uc {
                $!level = 2;
                .tclc;
            }
            else { $_ }
            self!heading: $name, :$!level;
            $.pod2pdf-xml($pod.contents);
        }
    }
}

method !heading($pod, Level:D :$level) {

    my $header-tag = $level
               ?? 'H' ~ $level
               !! 'H1';
    self!tag: $header-tag, {
        $.pod2pdf-xml($pod);
    }
}

# to reduce the common case <Hn><P>Xxxx<P></Hn> -> <Hn>Xxxx</Hn>
multi sub strip-para(List $_ where +$_ == 1) {
    .map(&strip-para).List;
}
multi sub strip-para(Pod::Block::Para $_) {
    .contents;
}
multi sub strip-para($_) { $_ }

multi method pod2pdf-xml(Pod::Heading $pod) {
    temp $!level = min($pod.level, 6);
    self!heading: $pod.contents.&strip-para(), :$!level;
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
    self!indent;
    self!add-content: '#comment' => (' ' ~ $.pod2text($pod).trim ~ ' ');
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
            self!tag: FENote, {
               $.pod2pdf-xml($pod.contents);
            }
        }
        when 'U' {
            self!tag: Span, :TextDecoration<Underline>, :inline, {
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
            my %atts = :role<Index>;
            %atts<Terms> = .[0].join('|') with $pod.meta;
            self!tag: Span, |%atts, {
                $.pod2pdf-xml: $pod.contents;
            }
        }
        when 'L' {
            my $text = $.pod2text-inline($pod.contents);
            my $href = $pod.meta.head // $text;
            sub link {
                self!tag: Link, :$href, :inline, {
                    $.pod2pdf-xml: $text;
                }
            }
            if $href.starts-with('#') {
                self!tag: Reference, :inline, {
                    link();
                }
            }
            else {
                link();
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

multi method pod2pdf-xml(Pod::Defn $pod) {
    my $number = @!numbering.tail;
    self!tag: ListItem, :role<Definition>, {
        if $number {
            self!tag: Label, {
                $.pod2pdf-xml($number.Str)
            }
        }
        self!tag: ListBody, {
            self!tag: Paragraph, :role<Term>, {
                $.pod2pdf-xml($pod.term);
            }
            $.pod2pdf-xml: $pod.contents;
        }
    }
}

multi method pod2pdf-xml(Pod::Block::Table $pod) {
    self!tag: Table, {
        if $pod.caption -> $caption {
            self!tag: Caption, {
                    $.pod2pdf-xml: $caption;
                }
            }
        if $pod.headers -> @headers {
            self!tag: TableHead, {
                self!tag: TableRow, {
                    @headers.map: {
                         self!tag: TableHeader, {
                             $.pod2pdf-xml: $_
                         }
                     }
                }
            }
        }
        self!tag: TableBody, {
            for $pod.contents -> @row {
                self!tag: TableRow, {
                    for @row -> $cell {
                        self!tag: TableData, {
                            $.pod2pdf-xml: $cell;
                        }
                    }
                }
            }
        }
    }
}

multi method pod2pdf-xml(Pod::Block::Declarator $pod) {
    my $w := $pod.WHEREFORE;

    my %spec := do given $w {
        when Method {
            my @params = .signature.params.skip(1);
            @params.pop if @params.tail.name eq '%_';
            %(
                :type((.multi ?? 'multi ' !! '') ~ 'method'),
                :code(.name ~ signature2text(@params, .returns)),
            )
        }
        when Sub {
            %(
                :type((.multi ?? 'multi ' !! '') ~ 'sub'),
                :code(.name ~ signature2text(.signature.params, .returns))
            )
        }
        when Attribute {
            my $code = .gist;
            $code .= subst('!', '.')
                if .has_accessor;
            my $name = .name.subst('$!', '');

            %(:type<attribute>, :$code, :$name, :decl<has>);
        }
        when .HOW ~~ Metamodel::EnumHOW {
            %(:type<enum>, :code(.raku() ~ signature2text($_.enums.pairs)));
        }
        when .HOW ~~ Metamodel::ClassHOW {
            %(:type<class>, :name(.^name), :level(2));
        }
        when .HOW ~~ Metamodel::ModuleHOW {
            %(:type<module>, :name(.^name), :level(2));
        }
        when .HOW ~~ Metamodel::SubsetHOW {
            %(:type<subset>, :code(.raku ~ ' of ' ~ .^refinee().raku));
        }
        when .HOW ~~ Metamodel::PackageHOW {
            %(:type<package>)
        }
        default {
            %()
        }
    }

    my Str $type = %spec<type> // '';
    my Level $level = %spec<level> // 3;
    my $name = %spec<name>  // $w.?name // '';
    my $decl = %spec<decl>  // $type;
    my $code = %spec<code>  // $w.raku;

    self!tag: Division, :role<Declaration>, {
        self!heading($type.tclc ~ ' ' ~ $name, :$level);

        if $pod.leading -> $leading {
            self!tag: Paragraph, {
                $.pod2pdf-xml($leading);
            }
        }

        self!tag: CODE, :Placement<Block>, :role<Raku>, {
            $.pod2pdf-xml: $decl ~ ' ' ~ $code;
        }

        if $pod.trailing -> $trailing {
            self!tag: Paragraph, {
                $.pod2pdf-xml($trailing);
            }
        }
    }
}

sub signature2text($params, Mu $returns?) {
    my constant NL = "\n    ";
    my $result = '(';

    if $params.elems {
        $result ~= NL ~ $params.map(&param2text).join(NL) ~ "\n";
    }
    $result ~= ')';
    unless $returns<> =:= Mu {
        $result ~= " returns " ~ $returns.raku
    }
    $result;
}
sub param2text($p) {
    $p.raku ~ ',' ~ ( $p.WHY ?? ' # ' ~ $p.WHY !! '')
}

multi method pod2pdf-xml(Pod::Item $pod) {
    my Str() $label = @!numbering.tail || do {
        my constant BulletPoints = ("\c[BULLET]",
                                    "\c[WHITE BULLET]",
                                    '-');
        BulletPoints[$pod.level-1] || BulletPoints.tail;
    }

    self!tag: ListItem, {
        {
            self!tag: Label, {
                $.pod2pdf-xml: $label;
            }
        }

        self!tag: ListBody, {
            $.pod2pdf-xml($pod.contents.&strip-para);
        }
    }
}

multi method pod2pdf-xml(Pod::Block::Code $pod) {
    my %atts = :Placement<Block>;
    %atts<role> = .lc with $pod.config<lang>;
    self!tag: CODE, |%atts, {
        $.pod2pdf-xml: $pod.contents;
    }
}

method !nest-list(@levels, $level) {
    while @levels && @levels.tail > $level {
        self!close-tag(LIST);
        @levels.pop;
    }
    if $level && (!@levels || @levels.tail < $level) {
        self!open-tag(LIST);
        @levels.push: $level;
    }
}

multi method pod2pdf-xml(List:D $pod) {
    my @levels;

    for $pod.list {
        my $level = do {
            when Pod::Item { .level }
            when Pod::Defn { 1 }
            default { 0 }
        }
        self!nest-list(@levels, $level);
        if .isa(Pod::Block) && .config<numbered> {
            @!numbering.tail++;
        }
        else {
            @!numbering.tail = 0;
        }

        $.pod2pdf-xml($_);
    }
    self!nest-list(@levels, 0);
}

multi method pod2pdf-xml(Str:D $text) {
    $!inlining = True;
    self!add-content: $text;
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

method !indent($n = 0) {
    my $depth = $n + @!tags;
    self!add-content: "\n" ~ '  ' x $depth
        if @!tags;
}

method !open-tag($tag) {
    self!indent unless $!inlining;
    @!numbering.push(0);
    my $tag-ast = $tag => [];
    @!tags.tail.value.push: $tag-ast if @!tags;
    @!tags.push: $tag-ast;
    $tag-ast;
}

method !close-tag(Str:D $tag where @!tags.tail.key ~~ $tag) {
    @!numbering.pop;
    self!indent(-1) unless $!inlining;
    @!tags.pop;
}

method !tag(Str:D $tag, &code, :$inline, *%atts) {
    $!inlining = True if $inline;
    my Pair $tag-ast := self!open-tag: $tag;
    $tag-ast.value.append: %atts.sort;
    &code();
    self!close-tag: $tag;
    $!inlining = False unless $inline;
    $tag-ast;
}


method !add-content($c) {
    die "no active tags" unless @!tags;
    # note "adding {$c.raku} to { @!tags.tail.key}";
    @!tags.tail.value.push: $c;
}
