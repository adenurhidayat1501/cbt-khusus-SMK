<?php
/**
 * Built-in PHP Development Server Router for Necis CBT
 * Allows running CBT directly via: php -S localhost:8080 router.php
 */

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$file = __DIR__ . $uri;

// 1. Static asset handling
if ($uri !== '/' && file_exists($file) && !is_dir($file)) {
    $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    
    // Security check: deny direct access to sensitive extensions
    if (in_array($ext, ['sql', 'log', 'env', 'git', 'sh', 'bat'])) {
        header("HTTP/1.1 403 Forbidden");
        exit('Access denied.');
    }

    $mimes = [
        'css'   => 'text/css',
        'js'    => 'application/javascript',
        'json'  => 'application/json',
        'png'   => 'image/png',
        'jpg'   => 'image/jpeg',
        'jpeg'  => 'image/jpeg',
        'gif'   => 'image/gif',
        'svg'   => 'image/svg+xml',
        'ico'   => 'image/x-icon',
        'woff'  => 'font/woff',
        'woff2' => 'font/woff2',
        'ttf'   => 'font/ttf',
        'eot'   => 'application/vnd.ms-fontobject',
        'pdf'   => 'application/pdf',
        'txt'   => 'text/plain',
        'xml'   => 'application/xml',
        'mp3'   => 'audio/mpeg',
        'wav'   => 'audio/wav',
        'ogg'   => 'audio/ogg',
    ];

    if (isset($mimes[$ext])) {
        header("Content-Type: " . $mimes[$ext]);
    }
    return false; // Let PHP built-in server handle the file
}

// 2. Handle installer requests
if (preg_match('#^/installer(/.*)?$#', $uri)) {
    if (is_file($file)) {
        require $file;
        return true;
    }
    require __DIR__ . '/installer/index.php';
    return true;
}

// 3. Forward all application requests to CodeIgniter front controller
$_SERVER['SCRIPT_NAME'] = '/index.php';
require_once __DIR__ . '/index.php';

