#!/usr/bin/env perl
use strict;
use warnings;

# This is a deliberately fail-closed, no-kernel lexical preflight for the
# constructs used by the adjacent Wolfram drivers.  It is not a replacement
# for held ToExpression: only a Wolfram parser can provide that guarantee.
# It supplements the delimiter checker with nested-comment/string handling
# and context-token continuity, the class that caused the V2 launch failure.

my %close_for = ('(' => ')', '[' => ']', '{' => '}');
my %is_close = map { $_ => 1 } values %close_for;
my $failed = 0;

sub report_failure {
    my ($name, $line, $column, $message) = @_;
    warn "$name:$line:$column $message\n";
    $failed = 1;
}

my @inputs = @ARGV ? @ARGV : ('-');
for my $name (@inputs) {
    my $handle;
    if ($name eq '-') {
        open $handle, '<&', \*STDIN or die "cannot duplicate stdin: $!\n";
    } else {
        open $handle, '<:raw', $name or die "cannot read $name: $!\n";
    }
    local $/;
    my $text = <$handle>;
    close $handle unless $name eq '-';
    $text = '' unless defined $text;

    my @stack;
    my $comment_depth = 0;
    my $comment_line = 0;
    my $comment_column = 0;
    my $in_string = 0;
    my $string_line = 0;
    my $string_column = 0;
    my $escaped = 0;
    my $line = 1;
    my $column = 1;

    for (my $i = 0; $i < length($text); ++$i) {
        my $char = substr($text, $i, 1);
        my $next = $i + 1 < length($text) ? substr($text, $i + 1, 1) : '';
        my $advance_pair = 0;

        if ($comment_depth > 0) {
            if ($char eq '(' && $next eq '*') {
                ++$comment_depth;
                $advance_pair = 1;
            } elsif ($char eq '*' && $next eq ')') {
                --$comment_depth;
                $advance_pair = 1;
            }
        } elsif ($in_string) {
            if ($escaped) {
                $escaped = 0;
            } elsif ($char eq '\\') {
                $escaped = 1;
            } elsif ($char eq '"') {
                $in_string = 0;
            }
        } elsif ($char eq '(' && $next eq '*') {
            $comment_depth = 1;
            $comment_line = $line;
            $comment_column = $column;
            $advance_pair = 1;
        } elsif ($char eq '"') {
            $in_string = 1;
            $string_line = $line;
            $string_column = $column;
        } elsif ($char eq '`') {
            if ($next eq '' || $next =~ /\s/) {
                report_failure($name, $line, $column,
                    'context delimiter must be immediately followed by a symbol token');
            }
        } elsif (exists $close_for{$char}) {
            push @stack, [$char, $line, $column];
        } elsif ($is_close{$char}) {
            if (!@stack || $close_for{$stack[-1][0]} ne $char) {
                report_failure($name, $line, $column,
                    "mismatched closing delimiter $char");
            } else {
                pop @stack;
            }
        }

        if ($advance_pair) {
            ++$i;
            if ($next eq "\n") {
                ++$line;
                $column = 1;
            } else {
                $column += 2;
            }
            next;
        }
        if ($char eq "\n") {
            ++$line;
            $column = 1;
        } else {
            ++$column;
        }
    }

    if ($comment_depth != 0) {
        report_failure($name, $comment_line, $comment_column,
            'unterminated nested comment');
    }
    if ($in_string) {
        report_failure($name, $string_line, $string_column,
            'unterminated string');
    }
    if (@stack) {
        report_failure($name, $stack[-1][1], $stack[-1][2],
            "unclosed delimiter $stack[-1][0]");
    }
}

exit($failed ? 1 : 0);
