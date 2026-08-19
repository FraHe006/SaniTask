const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const { spawn } = require('child_process');

// Importar conexiones a bases de datos
const { obtenerMySQL } = require('./conexionSQL');

// Crear aplicación Express
const app = express();
const servidor = http.createServer(app);

// Configurar WebSocket con Socket.IO
const io = socketIO(servidor, {
    cors: { origin: "*" }  // Permitir conexiones desde cualquier origen
});

// Middleware para leer JSON en las peticiones
app.use(express.json());

// ENDPOINTS DE PRODUCTOS (MySQL)

// ENDPOINTS DE EMPLEADOS CORREGIDOS

// Obtener TODOS los empleados
app.get('/api/empleados', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [empleados] = await mysql.query('SELECT * FROM empleados');
        res.json(empleados);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/empleado/validar', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const { usuario, codigoEmpleado } = req.body;

        const [empleados] = await mysql.query(
            'SELECT * FROM empleados WHERE nombre = ? AND numEmpleado = ?',
            [usuario, codigoEmpleado]
        );

        if (empleados.length === 0) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        res.json(empleados[0]);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Obtener UN empleado por su ID
app.get('/api/empleado/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [empleados] = await mysql.query(
            'SELECT * FROM empleados WHERE id = ?',
            [req.params.id]
        );

        if (empleados.length === 0) {
            return res.status(404).json({ error: 'Empleado no encontrado' });
        }

        res.json(empleados[0]);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Buscar empleados por nombre (búsqueda parcial)
app.get('/api/empleados/buscar/:nombre', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [empleados] = await mysql.query(
            'SELECT * FROM empleados WHERE nombre LIKE ?',
            [`%${req.params.nombre}%`]
        );
        res.json(empleados);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Crear un nuevo empleado
app.post('/api/empleado', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const {
            nombre, dni, fechaNacimiento, telefono, correo,
            numEmpleado, fechaAlta, unidad, catProfesional,
            titulacion, numColegiacion, certificaciones,
            reconocimiento, vacunaciones
        } = req.body;

        const [resultado] = await mysql.query(
            `INSERT INTO empleados (
                nombre, dni, fechaNacimiento, telefono, correo, 
                numEmpleado, fechaAlta, unidad, catProfesional, 
                titulacion, numColegiacion, certificaciones, 
                reconocimiento, vacunaciones
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                nombre, dni, fechaNacimiento, telefono, correo,
                numEmpleado, fechaAlta, unidad, catProfesional,
                titulacion, numColegiacion, certificaciones,
                reconocimiento, vacunaciones
            ]
        );

        res.status(201).json({
            mensaje: 'Empleado creado correctamente',
            id: resultado.insertId
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Editar un empleado por su ID
app.put('/api/empleado/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const {
            nombre, dni, fechaNacimiento, telefono, correo,
            numEmpleado, fechaAlta, unidad, catProfesional,
            titulacion, numColegiacion, certificaciones,
            reconocimiento, vacunaciones
        } = req.body;

        await mysql.query(
            `UPDATE empleados SET 
                nombre = ?, dni = ?, fechaNacimiento = ?, 
                telefono = ?, correo = ?, numEmpleado = ?, 
                fechaAlta = ?, unidad = ?, catProfesional = ?, 
                titulacion = ?, numColegiacion = ?, certificaciones = ?, 
                reconocimiento = ?, vacunaciones = ? 
            WHERE id = ?`,
            [
                nombre, dni, fechaNacimiento, telefono, correo,
                numEmpleado, fechaAlta, unidad, catProfesional,
                titulacion, numColegiacion, certificaciones,
                reconocimiento, vacunaciones, req.params.id
            ]
        );

        res.json({ mensaje: 'Empleado actualizado correctamente' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Borrar un empleado por su ID
app.delete('/api/empleado/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        await mysql.query(
            'DELETE FROM empleados WHERE id = ?',
            [req.params.id]
        );
        res.status(204).send();  // 204 No Content
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Obtener TODOS los pacientes
app.get('/api/pacientes', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [pacientes] = await mysql.query('SELECT * FROM pacientes');
        res.json(pacientes);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Obtener UN paciente por su ID
app.get('/api/paciente/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [pacientes] = await mysql.query(
            'SELECT * FROM pacientes WHERE id = ?',
            [req.params.id]
        );

        if (pacientes.length === 0) {
            return res.status(404).json({ error: 'Paciente no encontrado' });
        }

        res.json(pacientes[0]);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Buscar pacientes por nombre (búsqueda parcial)
app.get('/api/pacientes/buscar/:nombre', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [pacientes] = await mysql.query(
            'SELECT * FROM pacientes WHERE nombre LIKE ?',
            [`%${req.params.nombre}%`]
        );
        res.json(pacientes);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Crear un nuevo paciente
app.post('/api/paciente', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const {
            nombre, dni, fechaNacimiento, genero, sangre, rh, tarjetaSanitaria,
            telefono, correo, antecedentesFamiliares, vacunas, habitos,
            alergias, enfermedadesCronicas, tratamientoActual, cirugias
        } = req.body;

        const [resultado] = await mysql.query(
            `INSERT INTO pacientes (
                nombre, dni, fechaNacimiento, genero, sangre, rh, tarjetaSanitaria,
                telefono, correo, antecedentesFamiliares, vacunas, habitos,
                alergias, enfermedadesCronicas, tratamientoActual, cirugias
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                nombre, dni, fechaNacimiento, genero, sangre, rh, tarjetaSanitaria,
                telefono, correo, antecedentesFamiliares, vacunas, habitos,
                alergias, enfermedadesCronicas, tratamientoActual, cirugias
            ]
        );

        res.status(201).json({
            mensaje: 'Paciente creado correctamente',
            id: resultado.insertId
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Editar un paciente por su ID
app.put('/api/paciente/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const {
            nombre, dni, fechaNacimiento, genero, sangre, rh, tarjetaSanitaria,
            telefono, correo, antecedentesFamiliares, vacunas, habitos,
            alergias, enfermedadesCronicas, tratamientoActual, cirugias
        } = req.body;

        await mysql.query(
            `UPDATE pacientes SET 
                nombre = ?, dni = ?, fechaNacimiento = ?, genero = ?, sangre = ?, rh = ?, tarjetaSanitaria = ?,
                telefono = ?, correo = ?, antecedentesFamiliares = ?, vacunas = ?, habitos = ?,
                alergias = ?, enfermedadesCronicas = ?, tratamientoActual = ?, cirugias = ?
            WHERE id = ?`,
            [
                nombre, dni, fechaNacimiento, genero, sangre, rh, tarjetaSanitaria,
                telefono, correo, antecedentesFamiliares, vacunas, habitos,
                alergias, enfermedadesCronicas, tratamientoActual, cirugias,
                req.params.id
            ]
        );

        res.json({ mensaje: 'Paciente actualizado correctamente' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Borrar un paciente por su ID
app.delete('/api/paciente/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        await mysql.query(
            'DELETE FROM pacientes WHERE id = ?',
            [req.params.id]
        );
        res.status(204).send();  // 204 No Content
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Obtener citas del día filtradas por médico
app.get('/api/citas', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const hoy = new Date().toISOString().split('T')[0];
        const { responsableMedicoId } = req.query;

        let query = 'SELECT c.id, c.nombre, c.numIdentificacion, c.fechaNacimiento, c.fechaHoraCita, c.especialidadMedica, c.responsableMedicoId, e.nombre AS responsableMedicoNombre FROM citas c LEFT JOIN empleados e ON c.responsableMedicoId = e.id WHERE DATE(c.fechaHoraCita) = ?';
        let params = [hoy];

        if (responsableMedicoId) {
            query += ' AND c.responsableMedicoId = ?';
            params.push(parseInt(responsableMedicoId));
        }

        const [rows] = await mysql.query(query, params);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Obtener una cita específica con información del empleado
app.get('/api/citas/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [rows] = await mysql.query('SELECT c.*, e.nombre AS responsableMedicoNombre FROM citas c LEFT JOIN empleados e ON c.responsableMedicoId = e.id WHERE c.id = ?', [req.params.id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }
        res.json(rows[0]);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Crear una cita
app.post('/api/cita', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const { nombre, numIdentificacion, fechaNacimiento, fechaHoraCita, especialidadMedica, responsableMedicoId } = req.body;
        const [empleado] = await mysql.query('SELECT id FROM empleados WHERE id = ?', [responsableMedicoId]);
        if (empleado.length === 0) {
            return res.status(400).json({ error: 'El empleado responsable no existe' });
        }
        const resultado = await mysql.query('INSERT INTO citas (nombre, numIdentificacion, fechaNacimiento, fechaHoraCita, especialidadMedica, responsableMedicoId) VALUES (?, ?, ?, ?, ?, ?)', [nombre, numIdentificacion, fechaNacimiento, fechaHoraCita, especialidadMedica, responsableMedicoId]);
        res.status(201).json({ mensaje: 'Cita creada correctamente', id: resultado[0].insertId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Editar una cita
app.put('/api/cita/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const { nombre, numIdentificacion, fechaNacimiento, fechaHoraCita, especialidadMedica, responsableMedicoId } = req.body;
        const [citaExiste] = await mysql.query('SELECT id FROM citas WHERE id = ?', [req.params.id]);
        if (citaExiste.length === 0) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }
        const [empleado] = await mysql.query('SELECT id FROM empleados WHERE id = ?', [responsableMedicoId]);
        if (empleado.length === 0) {
            return res.status(400).json({ error: 'El empleado responsable no existe' });
        }
        await mysql.query('UPDATE citas SET nombre = ?, numIdentificacion = ?, fechaNacimiento = ?, fechaHoraCita = ?, especialidadMedica = ?, responsableMedicoId = ? WHERE id = ?', [nombre, numIdentificacion, fechaNacimiento, fechaHoraCita, especialidadMedica, responsableMedicoId, req.params.id]);
        res.json({ mensaje: 'Cita actualizada correctamente' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Borrar una cita
app.delete('/api/cita/:id', async (req, res) => {
    try {
        const mysql = obtenerMySQL();
        const [citaExiste] = await mysql.query('SELECT id FROM citas WHERE id = ?', [req.params.id]);
        if (citaExiste.length === 0) {
            return res.status(404).json({ error: 'Cita no encontrada' });
        }
        await mysql.query('DELETE FROM citas WHERE id = ?', [req.params.id]);
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.use(express.json());

app.post('/api/enviarCorreo', async (req, res) => {

    try {
        const { destinatario, asunto, cuerpo, adjunto } = req.body;

        // Validar campos obligatorios
        if (!destinatario || !asunto || !cuerpo) {
            return res.status(400).json({ error: "Faltan campos obligatorios" });
        }

        // Ejecutar script Python
        const python = spawn('python', ['enviarCorreo.py', JSON.stringify(req.body)]);

        let resultado = '';
        let errorOutput = '';

        python.stdout.on('data', (data) => resultado += data.toString());
        python.stderr.on('data', (data) => errorOutput += data.toString());

        python.on('close', (code) => {
            if (code === 0) {
                try {
                    const parsedResult = JSON.parse(resultado);
                    res.status(parsedResult.success ? 200 : 500).json(parsedResult);
                } catch {
                    res.status(200).send(resultado);
                }
            } else {
                res.status(500).json({ error: errorOutput || 'Error en script Python' });
            }
        });

        python.on('error', (err) => {
            res.status(500).json({ error: `No se pudo ejecutar Python: ${err.message}` });
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Iniciar el servidor
const PORT = process.env.PORT || 3000;
servidor.listen(PORT, () => {
    console.log(`Servidor escuchando en el puerto ${PORT}`);
    console.log(`http://localhost:${PORT}/`);
});
