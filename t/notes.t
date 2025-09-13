use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::XML::Reader;

plan 1;

my $xml = q{<Document Lang="en">
  <P>sanity test of <FENote>if you click, here, you should got back to the paragraph</FENote> footnotes.</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::XML::Reader $reader .= new: :indent;
$doc.write: $reader.render($=pod);
is $doc.Str, $xml,
    'Paragraphs convert correctly.';

=begin pod

=para sanity test of N<if you click, here, you should got back to the paragraph> footnotes.

=end pod
