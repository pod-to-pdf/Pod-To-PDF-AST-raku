# a small experiment
unit class Pod::To::PDF::ViaAST;

use Pod::To::PDF::ViaAST::Writer;
use Pod::To::PDF::AST;
use PDF::API6;

sub xml-header-opts(%hdr) {
    my %opts;

    for %hdr.keys.sort {
        when .starts-with: '!' {
            my $doctype = .substr(1);
            die "expected DOCTYPE 'Document', got '$doctype'"
                unless $doctype eq 'Document';
            %opts ,= :$doctype;
            %opts<system-id> = $_ with %hdr{$_}<system>;
        }
        when .starts-with: '?' {
            my $pi = .substr(1);
            warn "ignoring $pi processing instruction"
                unless $pi eq 'stylesheet';
            %opts<stylesheet> = $pi;
        }
        when /<ident>/ {
            %opts<root> =  $_ => %hdr{$_};
        }
        default {
            warn "ignoring '$_' directive in XML header";
        }
    }

    %opts;
}

method render(
    $class: $pod,
    Str:D :$save-as is copy = '/tmp/test.pdf',
    |c
) {
    state %cache{Any};
    %cache{$pod} //= do {
        my Bool $show-usage;
        for @*ARGS {
            when /^'--save-as='(.+)$/  { $save-as = $0.Str }
            default {  $show-usage = True; note "ignoring $_ argument" } 
        }
         note '(valid options are: --save-as=)'
             if $show-usage;
         my PDF::API6 $pdf .= new;
         my Pod::To::PDF::AST $reader .= new: :!indent, |c;
         my $ast = $reader.render($pod);
         my %opts = do given $ast.key {
             when '#xml'    { $ast.value.Hash.&xml-header-opts }
             when /<ident>/ { :root($ast) }
             default        { die "unexpected AST key '$_'" }
         }
         my Pair:D $root = %opts<root>:delete;
         my Pod::To::PDF::ViaAST::Writer $writer .= new: :$pdf, |%opts;
         $writer.ast2pdf($root);
         $pdf.save-as: $save-as;
    }
    $save-as;
}
