import requests
import sys


rollup = sys.argv[1]


def check_status_code(response):
    if response.status_code not in range(200, 300):
        print(f'[guest] Error: invalid status code {response.status_code}')
        sys.exit(1)
    return response


finish = {'status': 'accept'}
while True:
    print('[guest] Sending finish')
    r = check_status_code(requests.post(rollup + '/finish', json=finish))
    if r.status_code == 202:
        print('[guest] No pending rollup request, trying again')
        continue

    rollup_request = r.json()
    if rollup_request['request_type'] == 'advance_state':
        print(f"[guest] Got advance request, payload: {rollup_request['data']['payload']}")
        finish['status'] = 'accept'

    elif rollup_request['request_type'] == 'inspect_state':
        report = {'payload': rollup_request['data']['payload']}
        print(f'[guest] Sending report per inspect request, report {report}')
        check_status_code(requests.post(rollup + '/report', json=report))

    else:
        print('[guest] Throwing rollup exception')
        exception = {'payload': rollup_request['data']['payload']}
        requests.post(rollup + '/exception', json=exception)
        break
