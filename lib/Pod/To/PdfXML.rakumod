unit class Pod::To::PdfXML;

use LibXML::Item :&ast-to-xml;
use LibXML::Writer::Buffer;
use Pod::To::PdfAST;

method render (
    $class: $pod,
    Bool :$indent is copy = True,
    |c
) {
    state %cache{Any};
    %cache{$pod} //= do {
        my Bool $show-usage;
        for @*ARGS {
            when /^'--/indent'$/  { $indent = False }
            default {  $show-usage = True; note "ignoring $_ argument" } 
        }
         note '(valid options are: --/indent)'
             if $show-usage;
    }
    my Pod::To::PdfAST $writer .= new: :$indent, |c;
    my $ast = $writer.render($pod);
    my LibXML::Writer::Buffer $doc .= new;
    $doc.write($ast);
    ## $ast.&ast-to-xml.Str;
    $doc.Str;
}
