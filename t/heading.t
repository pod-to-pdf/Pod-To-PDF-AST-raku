use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::XML::AST;

plan 1;
my $xml = q{<Document Subject="for Pod::To::XML" Title="Heading tests" Lang="en">
  <Title>Heading tests</Title>
  <H2>for <Link href="Pod::To::XML">Pod::To::XML</Link></H2>
  <H1>Abbreviated heading1</H1>
  <P>asdf</P>
  <H1>Paragraph heading1</H1>
  <P>asdf</P>
  <H2>Subheading2</H2>
  <H1>
    <P>Structured</P>
    <P>heading1</P>
  </H1>
  <H3>Heading3</H3>
  <P>asdf</P>
  <H2>Head2</H2>
  <P>asdf</P>
  <H3>Head3</H3>
  <P>asdf</P>
  <H4>Head4</H4>
  <P>asdf</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::XML::AST $writer .= new: :indent;
$doc.write: $writer.render($=pod);
is $doc.Str, $xml,
   'Various types of headings convert correctly';

=begin pod
=TITLE Heading tests
=SUBTITLE for L<Pod::To::XML>

=head1 Abbreviated heading1

asdf

=for head1
Paragraph heading1

asdf

=head2 Subheading2

=begin head1
Structured
	
heading1
=end head1

=head3 	Heading3

asdf

=head2 Head2

asdf

=head3 Head3

asdf

=head4 Head4

asdf

=end pod
