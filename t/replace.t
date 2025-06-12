use Test;
plan 2;
use LibXML::Writer::Buffer;
use Pod::To::PDF::AST;

my $title = 'Sample Title';
my $date = '2025-03-17';
my $author = 'David Warring';
my $description = "sample Pod with replaced content";
my %replace = :$date, :$title, :$author, :$description;

my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Document SYSTEM "http://pdf-raku.github.io/dtd/tagged-pdf.dtd">
<Document Lang="en">
  <!-- sample Pod with replaced content -->
  <Title>Sample Title</Title>
  <H2>Replacement Test</H2>
  <H2>Author</H2>
  <P>David Warring</P>
  <H2>Date</H2>
  <P>2025-03-17</P>
  <H2>Description</H2>
  <P>sample Pod with replaced content;</P>
</Document>
};

my LibXML::Writer::Buffer $doc .= new;
my Pod::To::PDF::AST $writer .= new: :%replace;
$doc.write: $writer.render($=pod);
is $doc.Str, $xml,
   'Various types of replacement content correctly';

%replace<description> = $=pod;
$writer .= new: :%replace;
dies-ok {
    $writer.render($=pod, :%replace);
}, 'recursive replacement detected';


=begin pod
=comment sample Pod with replaced content
=TITLE R<title>
=SUBTITLE Replacement Test
=AUTHOR R<author>
=DATE R<date>
=head2 Description
=para R<description>;
=end pod
