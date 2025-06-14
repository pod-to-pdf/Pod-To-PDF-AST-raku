use v6;

use Test;
use LibXML::Writer::Buffer;
use Pod::To::PDF::AST;

plan 1;

my $xml = q{<Document Lang="en">
  <P>This text is of <Span TextDecoration="Underline">minor significance</Span>.</P>
  <P>This text is of <Em>major significance</Em>.</P>
  <P>This text is of <Strong>fundamental significance</Strong>.</P>
  <P>This text is verbatim C&lt;with&gt; B&lt;disarmed&gt; Z&lt;formatting&gt;.</P>
  <P>This text is to be replaced.</P>
  <P>This has invisible text.</P>
  <P>This text contains a link to <Link href="http://www.google.com/">http://www.google.com/</Link>.</P>
  <P>This text contains a link with label to <Link href="http://www.google.com/">google</Link>.</P>
  <!-- a real-world sample, taken from Supply.pod6 -->
  <P>A tap on an <Code>on demand</Code> supply will initiate the production of values, and tapping the supply again may result in a new set of values. For example, <Code>Supply.interval</Code> produces a fresh timer with the appropriate interval each time it is tapped. If the tap is closed, the timer simply stops emitting values to that tap.</P>
</Document>};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::AST $writer .= new: :indent;
$doc.write: $writer.render($=pod);
is $doc.Str, $xml,
   'Various types of formatting convert correctly.';

=begin pod
This text is of U<minor significance>.

This text is of I<major significance>.

This text is of B<fundamental significance>.

This text is V<verbatim C<with> B<disarmed> Z<formatting>>.

This text is R<to be replaced>.

This has Z<blabla>invisible text.

This text contains a link to L<http://www.google.com/>.

This text contains a link with label to L<google|http://www.google.com/>.

=comment a real-world sample, taken from Supply.pod6

A tap on an C<on demand> supply will initiate the production of values, and
tapping the supply again may result in a new set of values. For example,
C<Supply.interval> produces a fresh timer with the appropriate interval each
time it is tapped. If the tap is closed, the timer simply stops emitting values
to that tap.

=end pod
