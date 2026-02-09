# function_app.py
import logging
import os
import json
import pyodbc
import requests
from datetime import datetime
import azure.functions as func

app = func.FunctionApp()

@app.function_name(name="SchemaChangePoller")
@app.timer_trigger(
    schedule="0 */2 * * * *",  # Katras 2 minūtes
    arg_name="myTimer",
    run_on_startup=False
)
def poll_schema_changes(myTimer: func.TimerRequest) -> None:
    """
    Pārbauda vai ir jauns schema izmaiņas Test DB un
    aktivizē Azure DevOps pipeline
    """
    
    if myTimer.past_due:
        logging.info('Timer is past due!')
    
    logging.info('Schema change poller started at %s', datetime.utcnow())
    
    try:
        # 1. Savienoties ar SQL
        changes = get_unprocessed_changes()
        
        if not changes:
            logging.info('No unprocessed schema changes found')
            return
        
        logging.info(f'Found {len(changes)} unprocessed schema changes')
        
        # 2. Trigger pipeline
        run_id = trigger_pipeline(changes)
        
        if run_id:
            # 3. Atzīmēt kā processed
            change_ids = [c['ChangeId'] for c in changes]
            mark_as_processed(change_ids, run_id)
            
            logging.info(f'Successfully triggered pipeline. Run ID: {run_id}')
        else:
            logging.error('Failed to trigger pipeline')
            
    except Exception as e:
        logging.error(f'Error in schema change poller: {str(e)}', exc_info=True)


def get_unprocessed_changes():
    """Iegūt neapstrādātās izmaiņas no SQL"""
    
    connection_string = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={os.environ['SQL_SERVER']};"
        f"DATABASE={os.environ['SQL_DATABASE']};"
        f"UID={os.environ['SQL_USER']};"
        f"PWD={os.environ['SQL_PASSWORD']};"
        f"Encrypt=yes;TrustServerCertificate=no;"
    )
    
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    
    cursor.execute("EXEC dbo.usp_GetUnprocessedSchemaChanges")
    
    columns = [column[0] for column in cursor.description]
    changes = []
    
    for row in cursor.fetchall():
        change = dict(zip(columns, row))
        # Convert datetime to string
        change['ChangedAt'] = change['ChangedAt'].isoformat()
        changes.append(change)
    
    conn.close()
    
    return changes


def trigger_pipeline(changes):
    """Aktivizē Azure DevOps Pipeline"""
    
    org = os.environ['ADO_ORGANIZATION']
    project = os.environ['ADO_PROJECT']
    pipeline_id = os.environ['ADO_PIPELINE_ID']
    pat = os.environ['ADO_PAT']
    
    url = (
        f"https://dev.azure.com/{org}/{project}/"
        f"_apis/pipelines/{pipeline_id}/runs?api-version=7.0"
    )
    
    # Sagatavojam change summary
    change_summary = []
    for c in changes:
        change_summary.append({
            'object': f"{c['SchemaName']}.{c['ObjectName']}",
            'type': c['ObjectType'],
            'action': c['ChangeType'],
            'changedBy': c['ChangedBy'],
            'timestamp': c['ChangedAt']
        })
    
    payload = {
        'resources': {
            'repositories': {
                'self': {
                    'refName': 'refs/heads/main'
                }
            }
        },
        'templateParameters': {
            'triggerReason': 'schema_change_detected',
            'changeCount': str(len(changes)),
            'changes': json.dumps(change_summary)
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Basic {pat}'  # PAT jābūt base64 encoded
    }
    
    response = requests.post(url, json=payload, headers=headers)
    
    if response.status_code == 200:
        return response.json().get('id')
    else:
        logging.error(f'Pipeline trigger failed: {response.status_code} - {response.text}')
        return None


def mark_as_processed(change_ids, pipeline_run_id):
    """Atzīmē izmaiņas kā apstrādātas"""
    
    connection_string = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={os.environ['SQL_SERVER']};"
        f"DATABASE={os.environ['SQL_DATABASE']};"
        f"UID={os.environ['SQL_USER']};"
        f"PWD={os.environ['SQL_PASSWORD']};"
        f"Encrypt=yes;TrustServerCertificate=no;"
    )
    
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    
    change_ids_csv = ','.join(map(str, change_ids))
    
    cursor.execute(
        "EXEC dbo.usp_MarkSchemaChangesProcessed @ChangeIds=?, @PipelineRunId=?",
        (change_ids_csv, str(pipeline_run_id))
    )
    
    result = cursor.fetchone()
    conn.commit()
    conn.close()
    
    logging.info(f'Marked {result[0]} changes as processed')
