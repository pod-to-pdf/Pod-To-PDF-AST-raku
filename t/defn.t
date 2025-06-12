use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::AST;

plan 1;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Document SYSTEM "http://pdf-raku.github.io/dtd/tagged-pdf.dtd">
<Document Lang="en">
  <L>
    <LI role="Definition">
      <Lbl>1</Lbl>
      <LBody>
        <P role="Term">Happy</P>
        <P>When you're not blue.</P>
      </LBody>
    </LI>
    <LI role="Definition">
      <Lbl>2</Lbl>
      <LBody>
        <P role="Term">Blue</P>
        <P>When you're not happy.</P>
      </LBody>
    </LI>
  </L>
</Document>
};

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
