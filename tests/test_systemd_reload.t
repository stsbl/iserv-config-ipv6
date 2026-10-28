use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

my $tmp = tempdir(CLEANUP => 1);
my $log = "$tmp/systemctl.log";
path("$tmp/systemctl")->spew_utf8(<<'SH');
#!/bin/sh
printf '%s\n' "$*" >> "$SYSTEMCTL_TEST_LOG"
SH
chmod 0755, "$tmp/systemctl";
local $ENV{PATH} = "$tmp:$ENV{PATH}";
local $ENV{SYSTEMCTL_TEST_LOG} = $log;
for my $case (
    ['postinst', 'configure', 1],
    ['postinst', 'abort-upgrade', 0],
    ['postrm', 'remove', 1],
    ['postrm', 'purge', 1],
    ['postrm', 'upgrade', 0],
) {
    my ($script, $action, $reload) = @$case;
    ok(-f "debian/$script", "$script exists") or next;
    # Execute the actual script with an isolated systemd-running directory.
    my $content = path("debian/$script")->slurp_utf8;
    $content =~ s!/run/systemd/system!$tmp/running!g;
    path("$tmp/$script")->spew_utf8($content);
    for my $running (0, 1) {
        if ($running) { path("$tmp/running")->mkpath; }
        else { path("$tmp/running")->remove_tree; }
        path($log)->spew_utf8('');
        system('sh', "$tmp/$script", $action);
        is($? >> 8, 0, "$script $action succeeds (systemd=$running)");
        is(path($log)->slurp_utf8,
            $running && $reload ? "--system daemon-reload\n" : '',
            "$script $action reloads only when necessary (systemd=$running)");
    }
}
done_testing;
