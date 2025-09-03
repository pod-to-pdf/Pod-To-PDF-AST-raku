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


proto transform(Pair:D, Str:D, | --> Str:D) {*}

multi transform($ast, $fmt, Str:D :xls($file)!, :$indent!) {
    my LibXML::Element $root = $ast.&ast-to-xml;
    my LibXML::Document $doc .= new: :$root;
    my LibXSLT $xslt .= new();
    my LibXSLT::Stylesheet $stylesheet = $xslt.parse-stylesheet(:$file);
    my LibXSLT::Document::Xslt() $results = $stylesheet.transform(:$doc);
    $fmt eq 'json'
        ?? $results.ast.&transform('json', :$indent)
        !! $results.Str: :format($indent)
}

multi transform($ast, 'xml', :indent($format)) {
    $ast.&ast-to-xml.Str: :$format;
}

multi transform($ast, 'json', :indent($pretty)) {
    $ast.&to-json: :$pretty;
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
        when /^'--'(save\-as|xls)'='(.+)$/   { %opts{$0} = $1.Str }
        when /^'--'(format)'='(xml|html?|json)$/   { %opts{$0} = $1.Str }
        when /^'--'(format)'='(XML|HTML?|JSON)$/   { %opts{$0} = $1.Str.lc }
        default {  $show-usage = True; note "ignoring $_ argument" }
    }
    note '(valid options are: --/indent --format=xml|html|json --xls= --save-as=)'
        if $show-usage;
    %opts<format> //= do given %opts<save-as>//'' {
        when rx:i/'.'jso?n$/   { 'json' }
        when rx:i/'.'x?html?$/ { 'html' }
        default { 'xml' }
    }
    %opts<xls> //= %?RESOURCES<tagged-pdf.xsl>.IO.path
                     if %opts<format> eq 'html';
    %opts;
}

sub pod-render (
    $pod,
    Bool :$indent is copy = True,
    Str:D :$format!,
    Str :$save-as,
    |c
) {
    my Pod::To::XML::AST $writer .= new: :$indent, |c;
    my Pair $ast = $writer.render($pod);
    $ast.&transform($format, :$indent, |c).&output($save-as);
}

my %rendered{Any:D};

method render($pod, |c) {
    state %cache{Any};
    %cache{$pod} //= pod-render($pod, |get-opts, |c);
}

