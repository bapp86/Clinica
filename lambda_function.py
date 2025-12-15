import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json; charset=utf-8'
        },
        'body': json.dumps({
            'hospital': 'SanaVI',
            'sistema': 'Gestion de Pacientes',
            'estado': 'Activo',
            'mensaje': 'Conexion exitosa con Backend Serverless',
            'equipo_tecnico': ['Bryan Painemilla', 'Juan Crovetto'],
            'version': '1.0.0'
        }, indent=4, ensure_ascii=False)
    }
