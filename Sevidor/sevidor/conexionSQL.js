// conexionSQL.js
import mysql from "mysql2/promise";

const servidor = "localhost";
const usuario = "root";
const contra = "";
const bbdd = "prueba"; //hospital

// Crear pool de conexiones para MySQL
// El pool permite múltiples conexiones simultáneas
const pool = mysql.createPool({
    host: servidor,
    user: usuario,
    password: contra,
    database: bbdd,
    waitForConnections: true,
    connectionLimit: 10,  // Máximo de conexiones en el pool
    queueLimit: 0         // Sin límite en la cola de espera
});

// Función para obtener una conexión del pool
export function obtenerMySQL() {
    return pool;
}

// Probar conexión al iniciar la aplicación
pool.getConnection()
    .then(connection => {
        console.log("SQL Conectado correctamente");
        connection.release(); // Liberar la conexión de prueba
    })
    .catch(err => {
        console.error("Error al conectar SQL:", err);
    });