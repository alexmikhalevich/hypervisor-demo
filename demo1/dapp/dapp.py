import requests
import sys
from hypervisor import Hypervisor

rollup = sys.argv[1]

def check_status_code(response):
    if response.status_code not in range(200, 300):
        print(f'Error: invalid status code {response.status_code}')
        sys.exit(1)
    return response

hypervisor = Hypervisor()

finish = {'status': 'accept'}
while True:
    print('Sending finish')
    r = check_status_code(requests.post(rollup + '/finish', json=finish))
    if r.status_code == 202:
        print('No pending rollup request, trying again')
        continue

    rollup_request = r.json()
    if rollup_request['request_type'] == 'advance_state':
        print(f"Got advance request, payload: {rollup_request['data']['payload']}")
        text = bytes.fromhex(rollup_request['data']['payload'][2:]).decode("ascii")
        hypervisor.execute_python_script(text)
        finish['status'] = 'accept'

    elif rollup_request['request_type'] == 'inspect_state':
        print('Sending report per inspect request')
        report = {'payload': rollup_request['data']['payload']}
        check_status_code(requests.post(rollup + '/report', json=report))

    else:
        print('Throwing rollup exception')
        exception = {'payload': rollup_request['data']['payload']}
        requests.post(rollup + '/exception', json=exception)
        break
