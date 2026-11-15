<?php

class Database {
    private static ?PDO $connection = null;

    public static function getConnection(): PDO {
        if (self::$connection === null) {
            $host = getenv('DB_HOST') ?: 'db';
            $port = getenv('DB_PORT') ?: '5432';
            $dbname = getenv('DB_NAME') ?: 'appdb';
            $user = getenv('DB_USER') ?: 'appuser';
            $pass = getenv('DB_PASS') ?: 'apppass';

            $dsn = "pgsql:host={$host};port={$port};dbname={$dbname}";

            try {
                self::$connection = new PDO($dsn, $user, $pass, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]);
            } catch (PDOException $e) {
                die("Error de conexión con PostgreSQL (OceanConta): " . $e->getMessage());
            }
        }

        return self::$connection;
    }
}