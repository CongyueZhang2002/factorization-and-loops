#!/usr/bin/env perl
use strict;
use warnings;

my %close_for = ('(' => ')', '[' => ']', '{' => '}');
my %is_close = map { $_ => 1 } values %close_for;
my $failed = 0;

for my $file (@ARGV) {
    open my $handle, '<:raw', $file or die "cannot read $file: $!\n";
    local $/;
    my $text = <$handle>;
    close $handle;
    my @stack;
    my $comment_depth = 0;
    my $in_string = 0;
    my $escaped = 0;
    my $line = 1;
    for (my $i = 0; $i < length($text); ++$i) {
        my $char = substr($text, $i, 1);
        my $next = $i + 1 < length($text) ? substr($text, $i + 1, 1) : '';
        if ($char eq "\n") { ++$line; }
        if ($comment_depth > 0) {
            if ($char eq '(' && $next eq '*') {
                ++$comment_depth; ++$i;
            } elsif ($char eq '*' && $next eq ')') {
                --$comment_depth; ++$i;
            }
            next;
        }
        if ($in_string) {
            if ($escaped) { $escaped = 0; next; }
            if ($char eq '\\') { $escaped = 1; next; }
            if ($char eq '"') { $in_string = 0; }
            next;
        }
        if ($char eq '(' && $next eq '*') {
            $comment_depth = 1; ++$i; next;
        }
        if ($char eq '"') { $in_string = 1; next; }
        if (exists $close_for{$char}) {
            push @stack, [$char, $line];
            next;
        }
        if ($is_close{$char}) {
            if (!@stack || $close_for{$stack[-1][0]} ne $char) {
                warn "$file:$line mismatched closing $char\n";
                $failed = 1;
                last;
            }
            pop @stack;
        }
    }
    if ($comment_depth != 0 || $in_string || @stack) {
        my $detail = @stack ? "$stack[-1][0] opened line $stack[-1][1]" :
            $comment_depth ? 'unterminated comment' : 'unterminated string';
        warn "$file: unclosed $detail\n";
        $failed = 1;
    }
}

exit($failed ? 1 : 0);

