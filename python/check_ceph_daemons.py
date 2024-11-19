#!/usr/bin/env python3
import json
import subprocess
import argparse
import requests
import logging
import sys

# Constants
CEPH_CMD = ['ceph', 'orch', 'ps', '--format', 'json', '--daemon-type']
LOG_FILE = '/var/log/check_ceph_daemons.log'
URL_TIMEOUT=5

def get_daemons(daemon_type,debug=False):
    result = subprocess.run(CEPH_CMD + [daemon_type], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        logging.error("Failed to fetch "+ [daemon_type] + " daemon info.")
        return []

    data = json.loads(result.stdout)
    daemon_info = [(d['daemon_id'], d['hostname'],d['ports'][0]) for d in data]

    if debug:
        #logging.debug(f"{daemon_type} Daemons JSON:\n{json.dumps(data, indent=2)}")
        logging.debug(f"Processed {daemon_type} Daemons:\n{json.dumps(daemon_info, indent=2)}")

    return daemon_info

def check_daemon_health(daemon_type, daemon_info, debug=False):
    unhealthy = []
    for daemon_id, host, port in daemon_info:
        url = f"http://{host}:{port}"
        try:
            response = requests.get(url, timeout=URL_TIMEOUT)
            if response.status_code != 200:
                unhealthy.append((daemon_id, host))
        except Exception as e:
            if debug:
                logging.debug(f"Exception when checking {url}: {e}")
            unhealthy.append((daemon_id, host))

    if unhealthy:
        logging.debug(f"Unhealthy daemon_info: {daemon_type}.{daemon_id} on {host}")

    return unhealthy

def command_to_str(command_list):
    return ' '.join(command_list)



def main():
    parser = argparse.ArgumentParser(description='Restart unhealthy daemons')
    parser.add_argument('--debug', action='store_true', help='debugging log to stdout')
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(stream=sys.stdout, level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
    else:
        logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    target=['rgw', 'node-exporter']
    logging.debug(f"get {target} daemons")
    for daemon_type in target:
        command_list = CEPH_CMD + [daemon_type]
        logging.info(f"Start check {daemon_type}: {command_to_str(command_list)}")
        result = subprocess.run(command_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        daemon_info = get_daemons(daemon_type,debug=args.debug)
        if not daemon_info:
            logging.error(f"No {daemon_type} daemons found. Exiting.")
            return

        logging.info(f"# FYI: if you want restart {daemon_type} daemons manually")
        for daemon_id, host, port in daemon_info:
            logging.info(f"ceph orch daemon restart {daemon_type}.{daemon_id}")

        unhealthy_daemons = check_daemon_health(daemon_type, daemon_info, debug=args.debug)
        if not unhealthy_daemons:
            logging.info(f"All {daemon_type} daemons are healthy. No action needed.\n")
            continue

        for daemon_id, host in unhealthy_daemons:
            logging.info(f"Restarting unhealthy daemon: {daemon_type}.{daemon_id} on {host}.\n")
            logging.debug(f"ceph orch daemon restart {daemon_type}.{daemon_id}")
            subprocess.run(['ceph', 'orch', 'daemon', 'restart', f'{daemon_type}.{daemon_id}'])

if __name__ == "__main__":
    main()
