from flask import Flask, render_template
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Home page route"""
    hostname = os.getenv('HOSTNAME', 'Local Docker')
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    return render_template('index.html', 
                         hostname=hostname,
                         timestamp=timestamp)

@app.route('/health')
def health():
    """Health check endpoint for Azure Web App"""
    return {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'environment': os.getenv('ENVIRONMENT', 'development')
    }, 200

@app.route('/api/version')
def version():
    """API endpoint returning version info"""
    return {
        'app': 'Azure Docker CI/CD Demo',
        'version': '1.0.0',
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'container_id': os.getenv('HOSTNAME', 'unknown')
    }, 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)
