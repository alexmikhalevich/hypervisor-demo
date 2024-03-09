import requests
import sys
from flask import Flask, request


rollup = sys.argv[1]
host_ip = sys.argv[2]
app = Flask(__name__)


def check_status_code(response):
    if response.status_code not in range(200, 300):
        print(f'Error: invalid status code {response.status_code}')
        sys.exit(1)
    return response


# this endpoint is called by the guest dapp
# here we just forward the requests
@app.route('/finish', methods=['POST'])
def finish_endpoint():
    print('[host] Sending finish')
    r = check_status_code(requests.post(rollup + '/finish', json={'status': 'accept'}))
    if r.status_code == 202:
        print('[host] No pending rollup request, trying again')
        return '', 202

    rollup_request = r.json()
    return rollup_request, 200


# this endpoint is called by the guest dapp
# here we get the report from the guest dapp, modify it, and send it to the rollup
@app.route('/report', methods=['POST'])
def report_endpoint():
    report = request.json
    print(f'[host] Got report from guest: {report}')
    report['payload'] = '0xdeadbeef'
    check_status_code(requests.post(rollup + '/report', json=report))
    print(f'[host] Forwarded altered report: {report}')
    return '', 200


if __name__ == '__main__':
    app.run(host=host_ip, debug=True)
