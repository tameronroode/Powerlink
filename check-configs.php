<?php
$dir = __DIR__ . '/config';
$bad = [];
foreach (glob($dir . '/*.php') as $file) {
    set_error_handler(function () { });          // suppress notices from requires
    $v = require $file;
    restore_error_handler();
    if (!is_array($v)) {
        echo basename($file) . " -> NOT ARRAY\n";
        $bad[] = $file;
    }
}
if (!$bad) {
    echo "All config files return arrays. ✅\n";
}
