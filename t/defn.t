use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::AST;

plan 1;

my $xml = q{<Document Lang="en">
  <L>
    <LI role="DT">
      <Lbl Placement="Block" role="Term">Happy</Lbl>
      <LBody role="Definition">
        <P>When you're not blue.</P>
      </LBody>
    </LI>
    <LI role="DT">
      <Lbl Placement="Block" role="Term">Blue</Lbl>
      <LBody role="Definition">
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
