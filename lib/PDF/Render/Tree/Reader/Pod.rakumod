unit class PDF::Render::Tree::Reader::Pod;

use PDF::Render::Tree::Reader::Pod::Metadata;
also does PDF::Render::Tree::Reader::Pod::Metadata;

subset Level where 0..6;

has Pair:D @!tags;
has Str:D $.lang = 'en';
has $!level = 1;
has Bool $!inlining = False;
has Bool $.verbose;
has %.replace;
has Bool $.indent;
has @!item-nums;

enum Tags ( :Artifact<Artifact>, :BlockQuote<BlockQuote>, :Caption<Caption>, :CODE<Code>, :Division<Div>, :Document<Document>, :Header<H>, :Label<Lbl>, :LIST<L>, :ListBody<LBody>, :ListItem<LI>, :FootNote<FENote>, :Reference<Reference>, :Paragraph<P>, :Quote<Quote>, :Span<Span>, :Section<Sect>, :Table<Table>, :TableBody<TBody>, :TableHead<THead>, :TableHeader<TH>, :TableData<TD>, :TableRow<TR>, :Link<Link>, :Emphasis<Em>, :Strong<Strong>, :Title<Title> );

multi method render(::?CLASS:U: |c) {
    self.new.render(|c).raku;
}

multi method render(::?CLASS:D: $pod, :$tag = Document, |c) {
    my Pair $doc = self!tag: $tag, :Lang($!lang), {
        $.read($pod);
    }
    $doc.value.prepend: %.info.sort;
    $doc;
}

multi method read(Pod::Block::Named $pod) {
    given $pod.name {
        when 'pod'|'para' {
            $.read: $pod.contents;
        }
        when 'TITLE'|'SUBTITLE' {
            my Bool $toc = $_ eq 'TITLE';
            temp $!level = $_ eq 'TITLE' ?? 0 !! 2;
            self.metadata(.lc) ||= $.pod2text-inline($pod.contents);
            self!heading($pod.contents.&strip-para, :$toc, :$!level);
        }
        default {
            my $name = $_;
            temp $!level += 1;
            if $name eq .uc {
                if $name ~~ 'VERSION'|'NAME'|'AUTHOR' {
                    self.metadata(.lc) ||= $.pod2text-inline($pod.contents);
                }
                $!level = 2;
                $name .= tclc;
            }

            self!heading: $name, :$!level;
            $.read($pod.contents);
        }
    }
}

method !heading($pod, Level:D :$level) {

    my $header-tag = $level
               ?? 'H' ~ $level
               !! 'Title';
    self!tag: $header-tag, {
        $.read($pod);
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

multi method read(Pod::Heading $pod) {
    temp $!level = min($pod.level, 6);
    self!heading: $pod.contents.&strip-para(), :$!level;
}

multi method read(Pod::Block::Para $pod) {
    self!tag: Paragraph, {
        $.read($pod.contents);
    }
}

has Bool %!replacing;
method !replace(Pod::FormattingCode $pod where .type eq 'R', &continue) {
    my $place-holder = $.pod2text($pod.contents);

    die "unable to recursively replace R\<$place-holder\>"
         if %!replacing{$place-holder};
    temp  %!replacing{$place-holder} = True;

    my $new-pod = %!replace{$place-holder};

    $new-pod //= do {
        note "replacement not specified for R\<$place-holder\>"
           if $!verbose;
        $pod.contents;
    }

    &continue($new-pod);
}

multi method read(Pod::Block::Comment $pod) {
    self!indent;
    self!add-content: '#comment' => (' ' ~ $.pod2text($pod).trim ~ ' ');
}

multi method read(Pod::FormattingCode $pod) {
    given $pod.type {
        when 'B' {
            self!tag: Strong, :inline, {
                $.read($pod.contents);
            }
        }
        when 'C' {
            self!tag: CODE, {
                $.read($pod.contents);
            }
        }
        when 'T' {
            self!tag: CODE, :role<Terminal>, {
                $.read($pod.contents);
            }
        }
        when 'K' {
            self!tag: CODE, :role<Keyboard>, :TextDecorationType<Underline>, {
                $.read($pod.contents);
            }
        }
        when 'I' {
            self!tag: Emphasis, {
                $.read($pod.contents);
            }
        }
        when 'N' {
            self!tag: FootNote, {
               $.read($pod.contents);
            }
        }
        when 'U' {
            self!tag: Span, :TextDecorationType<Underline>, :inline, {
                $.read($pod.contents);
            }
        }
        when 'E' {
            $.read($pod.contents);
        }
        when 'Z' {
            # invisable
        }
        when 'X' {
            my %atts = :role<Index>;
            %atts<Terms> = .join('|') with $pod.meta.head;
            self!tag: Span, |%atts, {
                $.read: $pod.contents;
            }
        }
        when 'L' {
            my $text = $.pod2text-inline($pod.contents);
            my $href = $pod.meta.head // $text;
            sub link {
                self!tag: Link, :$href, :inline, {
                    $.read: $text;
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
                $.read: '(see: ';
                self!tag: Link, :$href, :inline, {
                    $.read: $href
                }
                $.read: ')';
            }
        }
        when 'R' {
            self!replace: $pod, {$.read($_)};
        }
        default {
            warn "unhandled: POD formatting code: $_\<\>";
            $.read: $pod.contents;
        }
    }
}

multi method read(Pod::Defn $pod) {
    # - ISO 32000-2 Table 368 Recommends using Lbl to enclose
    # - Match princexml tagging of HTML definition lists
    self!tag: ListItem, :role<DL-DIV>, {
        self!tag: Label, :role<DT>, :Placement<Block>, {
            $.read($pod.term);
        }
        self!tag: ListBody, :role<DD>, {
            $.read: $pod.contents;
        }
    }
}

multi method read(Pod::Block::Table $pod) {
    self!tag: Table, {
        if $pod.caption -> $caption {
            self!tag: Caption, {
                    $.read: $caption;
                }
            }
        if $pod.headers -> @headers {
            self!tag: TableHead, {
                self!tag: TableRow, {
                    @headers.map: {
                         self!tag: TableHeader, {
                             $.read: $_
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
                            $.read: $cell;
                        }
                    }
                }
            }
        }
    }
}

multi method read(Pod::Block::Declarator $pod) {
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
                $.read($leading);
            }
        }

        self!tag: CODE, :Placement<Block>, :role<Raku>, {
            $.read: $decl ~ ' ' ~ $code;
        }

        if $pod.trailing -> $trailing {
            self!tag: Paragraph, {
                $.read($trailing);
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

multi method read(Pod::Item $pod) {
    my $num = @!item-nums.grep({$_}).join('.');
    self!tag: ListItem, {
         if $num {
            self!tag: Label, {
                $.read: $num ~ '.'
            }
        }
        self!tag: ListBody, {
            $.read: $pod.contents;
        }
    }
}

multi method read(Pod::Block::Code $pod) {
    my %atts = :Placement<Block>;
    %atts<role> = .lc with $pod.config<lang>;
    self!tag: CODE, |%atts, {
        $.read: $pod.contents;
    }
}

method !nest-list($level, :$defn, :@levels!) {
    while @levels && @levels.tail > $level {
        self!close-tag: @!tags.tail.key;
        @levels.pop;
        @!item-nums.pop;
    }
    if $level && (!@levels || @levels.tail < $level) {
        given self!open-tag(LIST) {
            .value.push: (:role<DL>) if $defn;
        }

        @levels.push: $level;
        @!item-nums.push: 0;
    }
}

method !read-block($pod, :@levels!) {
    my Bool $defn;
    my $list-level = do given $pod {
        when Pod::Item { .level }
        when Pod::Defn { $defn = True; 1 }
        default { 0 }
    }
    self!nest-list: $list-level, :@levels, :$defn;

    if $list-level {
        with @!item-nums.tail -> $num is rw {
            if $pod.config<numbered> {
                $num++;
            }
            else {
                $num = 0;
            }
        }
    }

    $.read($pod);
}

multi method read(List:D $pod) {
    my @levels;

    for $pod.list {
        if .isa(Pod::Block) && !.isa(Pod::FormattingCode) {
            self!read-block($_, :@levels);
        }
        else {
            $.read($_);
        }
    }
    self!nest-list: 0, :@levels;
}

multi method read(Str:D $text) {
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
    if $.indent {
        my $depth = $n + @!tags;
        self!add-content: "\n" ~ '  ' x $depth
            if @!tags;
    }
}

method !open-tag($tag) {
    self!indent unless $!inlining;
    my $tag-ast = $tag => [];
    @!tags.tail.value.push: $tag-ast if @!tags;
    @!tags.push: $tag-ast;
    $tag-ast;
}

method !close-tag(Str:D $tag where @!tags.tail.key ~~ $tag) {
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
