use strict;
use warnings;
use Data::Dump qw(dump);
# Two way diff procedure for function style diff3.
# Change this as your like.
our $DIFF_PROC = \&_diff_heckel;

sub diff { return $DIFF_PROC->(@_) }

# the three-way diff based on the GNU diff3.c by R. Smith.
sub diff3 {
    my($text0, $text2, $text1) = @_;
    # diff result => [[$cmd, $loA, $hiA, $loB, $hiB], ...]
    my @diff2 = (
        diff($text2, $text0),
        diff($text2, $text1),
    );
    my $diff3 = [];
    my $range3 = [undef,  0, 0,  0, 0,  0, 0];
    while (@{$diff2[0]} || @{$diff2[1]}) {
        # find a continual range in text2 $lo2..$hi2
        # changed by text0 or by text1.
        #
        #  diff2[0]     222    222222222
        #     text2  ...L!!!!!!!!!!!!!!!!!!!!H...
        #  diff2[1]       222222   22  2222222
        my @range2 = ([], []);
        my $i =
              ! @{$diff2[0]} ? 1
            : ! @{$diff2[1]} ? 0
            : $diff2[0][0][1] <= $diff2[1][0][1] ? 0
            : 1;
        my $j = $i;
        my $k = $i ^ 1;
        my $hi = $diff2[$j][0][2];
        push @{$range2[$j]}, shift @{$diff2[$j]};
        while (@{$diff2[$k]} && $diff2[$k][0][1] <= $hi + 1) {
            my $hi_k = $diff2[$k][0][2];
            push @{$range2[$k]}, shift @{$diff2[$k]};
            if ($hi < $hi_k) {
                $hi = $hi_k;
                $j = $k;
                $k = $k ^ 1;
            }
        }
        my $lo2 = $range2[$i][ 0][1];
        my $hi2 = $range2[$j][-1][2];
        # take the corresponding ranges in text0 $lo0..$hi0
        # and in text1 $lo1..$hi1.
        #
        #     text0  ..L!!!!!!!!!!!!!!!!!!!!!!!!!!!!H...
        #  diff2[0]     222    222222222
        #     text2  ...00!1111!000!!00!111111...
        #  diff2[1]       222222   22  2222222
        #     text1       ...L!!!!!!!!!!!!!!!!H...
        my($lo0, $hi0);
        if (@{$range2[0]}) {
            $lo0 = $range2[0][ 0][3] - $range2[0][ 0][1] + $lo2;
            $hi0 = $range2[0][-1][4] - $range2[0][-1][2] + $hi2;
        }
        else {
            $lo0 = $range3->[2] - $range3->[6] + $lo2;
            $hi0 = $range3->[2] - $range3->[6] + $hi2;
        }
        my($lo1, $hi1);
        if (@{$range2[1]}) {
            $lo1 = $range2[1][ 0][3] - $range2[1][ 0][1] + $lo2;
            $hi1 = $range2[1][-1][4] - $range2[1][-1][2] + $hi2;
        }
        else {
            $lo1 = $range3->[4] - $range3->[6] + $lo2;
            $hi1 = $range3->[4] - $range3->[6] + $hi2;
        }
        $range3 = [undef,  $lo0, $hi0,  $lo1, $hi1,  $lo2, $hi2];
        # detect type of changes.
        if (! @{$range2[0]}) {
            $range3->[0] = '1';
        }
        elsif (! @{$range2[1]}) {
            $range3->[0] = '0';
        }
        elsif ($hi0 - $lo0 != $hi1 - $lo1) {
            $range3->[0] = 'A';
        }
        else {
            $range3->[0] = '2';
            for my $d (0 .. $hi0 - $lo0) {
                my($i0, $i1) = ($lo0 + $d - 1, $lo1 + $d - 1);
                my $ok0 = 0 <= $i0 && $i0 <= $#{$text0};
                my $ok1 = 0 <= $i1 && $i1 <= $#{$text1};
                if ($ok0 ^ $ok1 || ($ok0 && $text0->[$i0] ne $text1->[$i1])) {
                    $range3->[0] = 'A';
                    last;
                }
            }
        }
        push @{$diff3}, $range3;
    }
    return $diff3;
}

sub merge {
    my($mytext, $origtext, $yourtext) = @_;
    my $text3 = [$mytext, $yourtext, $origtext];
    my $res = {conflict => 0, body => []};
    my $diff3 = diff3(@{$text3}[0, 2, 1]);
    my $i2 = 1;

    for my $r3 (@{$diff3}) {
        for my $lineno ($i2 .. $r3->[5] - 1) {
            push @{$res->{body}}, $text3->[2][$lineno - 1];
        }
        if ($r3->[0] eq '0') {
            for my $lineno ($r3->[1] .. $r3->[2]) {
                push @{$res->{body}}, $text3->[0][$lineno - 1];
            }
        }
        elsif ($r3->[0] ne 'A') {
            for my $lineno ($r3->[3] .. $r3->[4]) {
                push @{$res->{body}}, $text3->[1][$lineno - 1];
            }
        }
        else {
            _conflict_range($text3, $r3, $res);
        }
        $i2 = $r3->[6] + 1;
    }
    for my $lineno ($i2 .. $#{$text3->[2]} + 1) {
        push @{$res->{body}}, $text3->[2][$lineno - 1];
    }
    return $res;
}

sub _conflict_range {
    my($text3, $r3, $res) = @_;
    #print text3;
    my $text2 = [
        [map { $text3->[1][$_ - 1] } $r3->[3] .. $r3->[4]], # yourtext
        [map { $text3->[0][$_ - 1] } $r3->[1] .. $r3->[2]], # mytext
    ];

    my $diff = diff(@{$text2});
    if (_assoc_range($diff, 'c') && $r3->[5] <= $r3->[6]) {
        $res->{conflict}++;
        push @{$res->{body}}, '<<<<<<<';
        for my $lineno ($r3->[1] .. $r3->[2]) {
            push @{$res->{body}}, $text3->[0][$lineno - 1];
        }
        push @{$res->{body}}, '|||||||';
        for my $lineno ($r3->[5] .. $r3->[6]) {
            push @{$res->{body}}, $text3->[2][$lineno - 1];
        }
        push @{$res->{body}}, '=======';
        for my $lineno ($r3->[3] .. $r3->[4]) {
            push @{$res->{body}}, $text3->[1][$lineno - 1];
        }
        push @{$res->{body}}, '>>>>>>>';
        return;
    }
    my $ia = 1;
    for my $r2 (@{$diff}) {
        for my $lineno ($ia .. $r2->[1] - 1) {
            push @{$res->{body}}, $text2->[0][$lineno - 1];
        }
        if ($r2->[0] eq 'c') {
            $res->{conflict}++;
            push @{$res->{body}}, '<<<<<<<';
            for my $lineno ($r2->[3] .. $r2->[4]) {
                push @{$res->{body}}, $text2->[1][$lineno - 1];
            }
            push @{$res->{body}}, '=======';
            for my $lineno ($r2->[1] .. $r2->[2]) {
                push @{$res->{body}}, $text2->[0][$lineno - 1];
            }
            push @{$res->{body}}, '>>>>>>>';
        }
        elsif ($r2->[0] eq 'a') {
            for my $lineno ($r2->[3] .. $r2->[4]) {
                push @{$res->{body}}, $text2->[1][$lineno - 1];
            }
        }
        $ia = $r2->[2] + 1;
    }
    for my $lineno ($ia .. $#{$text2->[0]} + 1) {
        push @{$res->{body}}, $text2->[0][$lineno - 1];
    }
    return;
}

sub _assoc_range {
    my($diff, $type) = @_;
    for my $r (@{$diff}) {
        return $r if $r->[0] eq $type;
    }
    return;
}

# the two-way diff based on the algorithm by P. Heckel.
sub _diff_heckel {
    my($text_a, $text_b) = @_;
    my $diff = [];
    my @uniq = ([$#{$text_a} + 1, $#{$text_b} + 1]);

    my(%freq, %ap, %bp);
    for my $i (0 .. $#{$text_a}) {
        my $s = $text_a->[$i];
        $freq{$s} += 2;
        $ap{$s} = $i;
    }
    for my $i (0 .. $#{$text_b}) {
        my $s = $text_b->[$i];
        $freq{$s} += 3;
        $bp{$s} = $i;
    }
    while (my($s, $x) = each %freq) {
        next if $x != 5;
        push @uniq, [$ap{$s}, $bp{$s}];
    }
   
    %freq = (); %ap = (); %bp = ();
    @uniq = sort { $a->[0] <=> $b->[0] } @uniq;
    my($a1, $b1) = (0, 0);
    while ($a1 <= $#{$text_a} && $b1 <= $#{$text_b}) {
        last if $text_a->[$a1] ne $text_b->[$b1];
        ++$a1;
        ++$b1;
    }
    
    for (@uniq) {
        my($a_uniq, $b_uniq) = @{$_};
        next if $a_uniq < $a1 || $b_uniq < $b1;
        my($a0, $b0) = ($a1, $b1);
        ($a1, $b1) = ($a_uniq - 1, $b_uniq - 1);
        while ($a0 <= $a1 && $b0 <= $b1) {
            last if $text_a->[$a1] ne $text_b->[$b1];
            --$a1;
            --$b1;
        }
        if ($a0 <= $a1 && $b0 <= $b1) {
            push @{$diff}, ['c', $a0 + 1, $a1 + 1, $b0 + 1, $b1 + 1];
        }
        elsif ($a0 <= $a1) {
            push @{$diff}, ['d', $a0 + 1, $a1 + 1, $b0 + 1, $b0];
        }
        elsif ($b0 <= $b1) {
            push @{$diff}, ['a', $a0 + 1, $a0, $b0 + 1, $b1 + 1];
        }
        ($a1, $b1) = ($a_uniq + 1, $b_uniq + 1);
        while ($a1 <= $#{$text_a} && $b1 <= $#{$text_b}) {
            last if $text_a->[$a1] ne $text_b->[$b1];
            ++$a1;
            ++$b1;
        }
    }
    return $diff;
}

my $base =  ["Some stuff:","<p>","This calculation can</p>","","","","</p>"];
my $left =  ["Some stuff:","<figref id=\"30835\"></figref>","<p>", "This calculation can</p>","</p>"];
my $right = ["Some stuff:","<p>","This calculation can</p>","<figref id=\"30836\"></figref>","</p>"];

# print @left;

my @x = merge($left, $base, $right);
# #         split('Some stuff:\n<figref id=\"30835\"></figref>\n<p>\nThis calculation can</p>\n</p>\n'),
# #         split('Some stuff:\n<p>\nThis calculation can</p>\n\n\n</p>\n', "\n"),
# #         split('Some stuff:\n<p>\nThis calculation can</p>\n<figref id=\"30836\"></figref>\n</p>\n')
# #     );
print dump(@x);
1;