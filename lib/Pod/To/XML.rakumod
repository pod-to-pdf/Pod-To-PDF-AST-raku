unit class Pod::To::XML;

use LibXML::Element;
use LibXML::Document;
use LibXML::Item :&ast-to-xml;
use LibXSLT;
use LibXSLT::Stylesheet;
use LibXSLT::Document;
use Pod::To::XML::AST;
use JSON::Fast;

multi save($ast, Str:U :$save-as, |c) {
    my LibXML::Element $xml = $ast.&ast-to-xml;
    $xml.Str;
}

multi save($ast, Str:D :$save-as where rx:i/ '.'jso?n$/, |c) {
    $save-as.IO.spurt: $ast.&to-json;
    'file://' ~ $save-as;
}

multi save($ast, Str:D :$save-as where rx:i/ '.'xml$/, |c) {
    my LibXML::Element $xml = $ast.&ast-to-xml;
    $save-as.IO.spurt: $xml.Str;
    'file://' ~ $save-as;
}

multi save($ast, Str:D :$save-as where rx:i/ '.'x?html?$/, |c) {
    my LibXML::Element $root = $ast.&ast-to-xml;
    my LibXML::Document $doc .= new: :$root;
    my LibXSLT $xslt .= new();
    my Str:D  $file = %?RESOURCES<tagged-pdf.xsl>.IO.path;
    my LibXSLT::Stylesheet $stylesheet = $xslt.parse-stylesheet(:$file);
    my LibXSLT::Document::Xslt() $results = $stylesheet.transform(:$doc);
    $save-as.IO.spurt: $results.Str;
    'file://' ~ $save-as;
}

sub get-opts {
    my Bool $show-usage;
    my %opts;
    for @*ARGS {
        when /^'--'('/')?(indent)$/      { %opts{$1} = ! $0.so }
        when /^'--'(save\-as)'='(.+)$/   { %opts{$0} = $1.Str }
        default {  $show-usage = True; note "ignoring $_ argument" }
    }
    note '(valid options are: --/indent --save-as=)'
        if $show-usage;
    %opts;
}

sub pod-render (
    $pod,
    Bool :$indent is copy = True,
    Str :$save-as,
    |c
) {
    state %cache{Any};
    %cache{$pod} //= do {
    }
    my Pod::To::XML::AST $writer .= new: :$indent, |c;
    my Pair $ast = $writer.render($pod);
    $ast.&save(:$save-as);
}

method render($pod, Str :$save-as, |c) {
    state $rendered //= do {
        my %opts = get-opts;
        pod-render($pod, |%opts, |c);
    }
}

