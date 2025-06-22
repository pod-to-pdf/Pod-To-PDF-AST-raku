use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::AST;

plan 1;

my $xml = q{<Document Lang="en">
  <L>
    <LI role="DL-DIV">
      <Lbl Placement="Block" role="DT">Happy</Lbl>
      <LBody role="DD">
        <P>When you're not blue.</P>
      </LBody>
    </LI>
    <LI role="DL-DIV">
      <Lbl Placement="Block" role="DT">Blue</Lbl>
      <LBody role="DD">
        <P>When you're not happy.</P>
      </LBody>
    </LI>
  </L>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::AST $writer .= new: :indent;
$doc.write: $writer.render($=pod);
is $doc.Str, $xml,
   'Definitions convert correctly.';

=begin pod

=defn # Happy
When you're not blue.

=defn # Blue
When you're not happy.

=end pod
