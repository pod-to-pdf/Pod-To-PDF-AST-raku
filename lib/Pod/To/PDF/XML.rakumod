unit class Pod::To::PDF::XML;

use LibXML::Item :&ast-to-xml;
use LibXML::Writer::Buffer;
use Pod::To::PDF::XML::Writer;

method render (
    $class: $pod,
    Str:D :$save-as is copy = '-',
    |c
) {
    state %cache{Any};
    %cache{$pod} //= do {
        my Bool $show-usage;
        for @*ARGS {
            when /^'--save-as='(.+)$/  { $save-as = $0.Str }
            default {  $show-usage = True; note "ignoring $_ argument" } 
        }
         note '(valid options are: --save-as=)'
             if $show-usage;
    }
    my Pod::To::PDF::XML::Writer $writer .= new: |c;
    my $ast = $writer.render($pod);
    my LibXML::Writer::Buffer $doc .= new;
    $doc.write($ast);
    $doc.Str;
}
