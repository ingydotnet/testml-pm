use lib 'lib';
use TestML::Compiler;
use YAML::XS;
use IO::All;

for my $path (glob('t/testml/*.tml')) {
    (my $file = $path) =~ s!.*/!!;
    next if $file eq 'comments.tml';
    next if $file eq 'data.tml';
    next if $file eq 'external1.tml';
    next if $file eq 'external2.tml';
    next if $file eq 'syntax.tml';
    next if $file eq 'topic.tml';
    print $file,"\n";
    my $function = TestML::Compiler->new->compile($path);
    io("ast/$file")->print(Dump($function));
}
