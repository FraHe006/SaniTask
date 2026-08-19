import sys
import json
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

try:
    # Parsear datos recibidos
    datos = json.loads(sys.argv[1])
    
    destinatario = datos["destinatario"]
    asunto = datos["asunto"]
    cuerpo = datos["cuerpo"]
    adjunto = datos.get("adjunto", "")  # Nombre del archivo PDF
    
    # Configuración email
    sender = "helena.franz.folgueira@colexio-karbo.com"
    app_password = "mdpd yqxc oghn efap"
    
    # Crear mensaje
    msg = MIMEMultipart()
    msg["From"] = sender
    msg["To"] = destinatario
    msg["Subject"] = asunto
    msg.attach(MIMEText(cuerpo, "plain"))
    
    # Adjuntar PDF si existe
    if adjunto:
        downloads_path = os.path.join(os.path.expanduser("~"), "Downloads")
        archivo_path = os.path.join(downloads_path, adjunto)
        
        if os.path.exists(archivo_path):
            with open(archivo_path, "rb") as archivo:
                part = MIMEBase("application", "octet-stream")
                part.set_payload(archivo.read())
                encoders.encode_base64(part)
                part.add_header("Content-Disposition", f"attachment; filename={adjunto}")
                msg.attach(part)
    
    # Enviar correo
    with smtplib.SMTP("smtp.gmail.com", 587) as server:
        server.starttls()
        server.login(sender, app_password)
        server.send_message(msg)
    
    print(json.dumps({"success": True, "message": f"Correo enviado a {destinatario}"}))

except Exception as e:
    print(json.dumps({"success": False, "error": str(e)}))
    sys.exit(1)