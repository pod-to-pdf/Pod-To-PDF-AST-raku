unit class Pod::To::XML;

use LibXML::Element;
use LibXML::Document;
use LibXML::Item :&ast-to-xml;
use LibXSLT;
use LibXSLT::Stylesheet;
use LibXSLT::Document;
use Pod::To::XML::AST;
use JSON::Fast;

sub format { enum <xml html json raku> }
my subset Format of Str:D where format{$_}:exists;


proto transform(Pair:D, Str:D, :indent($) --> Str:D) {*}

multi transform($ast, 'xml', :indent(:$format)) {
    $ast.&ast-to-xml.Str: :$format;
}

multi transform($ast, 'json', :indent($pretty)) {
    $ast.&to-json: :$pretty;
}

multi transform($ast, 'html', :indent(:$format)) {
    my LibXML::Element $root = $ast.&ast-to-xml;
    my LibXML::Document $doc .= new: :$root;
    my LibXSLT $xslt .= new();
    my Str:D  $file = %?RESOURCES<tagged-pdf.xsl>.IO.path;
    my LibXSLT::Stylesheet $stylesheet = $xslt.parse-stylesheet(:$file);
    my LibXSLT::Document::Xslt() $results = $stylesheet.transform(:$doc);
    $results.Str: :$format;
}

sub xml-escape(Str:D $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
}
multi output(Str:D $s, Str:D $save-as!) {
        $save-as.IO.spurt: $s;
        'file://' ~ $save-as.&xml-escape;
}
multi output(Str:D $s, Str:U) { $s }

sub get-opts {
    my Bool $show-usage;
    my %opts;
    for @*ARGS {
        when /^'--'('/')?(indent)$/      { %opts{$1} = ! $0.so }
        when /^'--'(save\-as)'='(.+)$/   { %opts{$0} = $1.Str }
        when /^'--'(format)'='(xml|html?|json)$/   { %opts{$0} = $1.Str }
        default {  $show-usage = True; note "ignoring $_ argument" }
    }
    note '(valid options are: --/indent --format= --save-as=)'
        if $show-usage;
    %opts<format> //= do given %opts<save-as> {
        when rx:i/'.'jso?n$/   { 'json' }
        when rx:i/'.'x?html?$/ { 'html' }
        default { 'xml' }
    }
    %opts;
}

sub pod-render (
    $pod,
    Bool :$indent is copy = True,
    Str:D :$format!,
    Str :$save-as,
    |c
) {
    state %cache{Any};
    %cache{$pod} //= do {
    }
    my Pod::To::XML::AST $writer .= new: :$indent, |c;
    my Pair $ast = $writer.render($pod);
    $ast.&transform($format, :$indent).&output($save-as);
}

method render($pod, Str :$save-as, |c) {
    state $rendered //= do {
        my %opts = get-opts;
        pod-render($pod, |%opts, |c);
    }
}

