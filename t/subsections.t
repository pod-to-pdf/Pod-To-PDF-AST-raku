use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::AST;

plan 1;

my $xml = q{<Document Lang="en">
  <H2>Outer</H2>
  <P>This is an outer paragraph</P>
  <H3>Inner1</H3>
  <P>This is the first inner paragraph</P>
  <H3>Inner2</H3>
  <P>This is the second inner paragraph</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::AST $writer .= new: :indent;
$doc.write: $writer.render($=pod);
is $doc.Str, $xml,
   'Various types of paragraphs nest correctly';


=begin pod
=begin Outer

This is an outer paragraph

=begin Inner1

This is the first inner paragraph

=end Inner1

    =begin Inner2

    This is the second inner paragraph

    =end Inner2
=end Outer
=end pod
