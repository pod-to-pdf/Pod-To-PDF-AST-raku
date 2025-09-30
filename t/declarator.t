use v6;

use Test;
use LibXML::Writer::Buffer;
use PDF::Render::Tree::From::Pod;

plan 1;

my $xml = q{<Document lang="en">
  <!-- Example taken from docs.raku.org/language/pod#Declarator_blocks -->
  <Div role="Declaration">
    <H2>Class Magician</H2>
    <P>Base class for magicians</P>
    <Code Placement="Block" role="Raku">class Magician</Code>
  </Div>
  <Div role="Declaration">
    <H3>Sub duel</H3>
    <P>Fight mechanics</P>
    <Code Placement="Block" role="Raku">sub duel(
    Magician $a,
    Magician $b,
)</Code>
    <P>Magicians only, no mortals.</P>
  </Div>
</Document>};

my PDF::Render::Tree::From::Pod $reader .= new: :indent;
my $ast = $reader.render($=pod);
my LibXML::Writer::Buffer $doc .= new;
$doc.write($ast);
is $doc.Str, $xml,
   'Declarators convert correctly.';

=comment Example taken from docs.raku.org/language/pod#Declarator_blocks

#| Base class for magicians 
class Magician {
  has Int $.level;
  has Str @.spells;
}
 
#| Fight mechanics 
sub duel(Magician $a, Magician $b) {
}
#= Magicians only, no mortals. 

