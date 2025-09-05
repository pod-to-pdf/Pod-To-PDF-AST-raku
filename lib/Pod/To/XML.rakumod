unit class Pod::To::XML;

use LibXML::Element;
use LibXML::Document;
use LibXML::Item :&ast-to-xml;
use LibXSLT;
use LibXSLT::Stylesheet;
use LibXSLT::Document;
use Pod::To::XML::Writer;
use JSON::Fast;

sub format { enum <xml html json raku> }
my subset Format of Str:D where format{$_}:exists;

sub doc(Pair:D $ast --> LibXML::Document:D) {
    my LibXML::Item $root = $ast.&ast-to-xml;
    $root.isa(LibXML::Document)
        ?? $root
        !! LibXML::Document.new: :$root;
}

sub xslt(Pair $ast, $file --> Pair) {
    my LibXML::Document $doc = $ast.&doc;
    my LibXSLT $xslt .= new();
    my LibXSLT::Stylesheet $stylesheet = $xslt.parse-stylesheet(:$file);
    my LibXSLT::Document::Xslt() $results = $stylesheet.transform(:$doc);
    $results.ast;
}

proto transform(Pair:D, Str:D, |c --> Str:D) {*}

multi transform($ast, 'html', Str:D :xls($file) = %?RESOURCES<tagged-pdf.xsl>.IO.path, :indent($format)!) {
    $ast.&xslt($file).&doc.Str: :html, :$format;
}

multi transform($ast, $type, Str:D :$xls!, |c) {
    $ast.&xslt($xls).&transform($type, |c)
}

multi transform($ast, 'xml', :indent($format)) {
    $ast.&doc.Str: :$format;
}

multi transform($ast, 'json', :indent($pretty)) {
    $ast.&to-json: :$pretty
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

sub get-opts is hidden-from-backtrace {
    my Bool $show-usage;
    my %opts;
    for @*ARGS {
        when /^'--'('/')?(indent|style)$/    { %opts{$1} = ! $0.so }
        when /^'--'('/')?(html|json)$/       { %opts<format> = $1.Str unless $0 }
        when /^'--'(save\-as|xls)'='(.+)$/   { %opts{$0} = $1.Str }
        when /^'--'(format)'='[:i(xml|html|json)]$/   { %opts{$0} = $1.lc }
        default {  $show-usage = True; note "ignoring $_ argument" }
    }
    fail '(valid options are: --/indent --format=xml|html|json --xls= --save-as=)'
        if $show-usage;
    %opts<format> //= do with %opts<save-as> {
        when rx:i/'.'jso?n$/   { 'json' }
        when rx:i/'.'x?html?$/ { 'html' }
    } // 'xml';
    %opts;
}

our sub render (
    $pod,
    Bool :$indent is copy = True,
    Str:D :$format = 'xml',
    Str :$save-as,
    |c
) {
    my Pod::To::XML::Writer $writer .= new: |c;
    my Pair $ast = $writer.render($pod);
    $ast.&transform($format, :$indent, |c).&output($save-as);
}

method render($pod, |c) is hidden-from-backtrace {
    state %cache{Any};
    %cache{$pod} //= render($pod, |get-opts, |c);
}

