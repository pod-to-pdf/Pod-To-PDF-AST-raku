# a small experiment
unit class Pod::To::PDF::ViaAST;

use Pod::To::PDF::ViaAST::Writer;
use Pod::To::PDF::AST;
use PDF::API6;

method render(
    $class: $pod,
    Str:D :$save-as is copy = '/tmp/test.pdf',
    |c
) {
    state %cache{Any};
    %cache{$pod} //= do {
        my Bool $show-usage;
         my PDF::API6 $pdf .= new;
         my Pod::To::PDF::AST $reader .= new: :!indent, |c;
         my $root = $reader.render($pod);
         my Pod::To::PDF::ViaAST::Writer $writer .= new: :$pdf, |%opts;
         $writer.ast2pdf($root);
         $pdf.save-as: $save-as;
    }
    $save-as;
}
