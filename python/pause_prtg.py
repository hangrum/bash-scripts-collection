#!/usr/bin/python3
import requests
import json
import sys
auth = {'username': 'ansible', 'passhash': 'pass_hash_blabla'}
URL='http://prtg.server.com'

class AuthPRTG:
  def __init__(self, auth, URL):
    self.auth = auth
    self.URL = URL
    r = requests.get(URL+'/api/healthstatus.json',params=auth,timeout=20)
    if r.status_code != 200:
      raise Exception(r.status_code, r.reason)

class PrtgAPI(AuthPRTG):
  def __init__(self, auth, URL, hostname = None):
    super().__init__(auth, URL)
    self.hostname = hostname
    self.params = {}
    self.params.update(auth)
    self.deviceId = []
    self.switch = None

  def searchByDevice(self):
    API = '/api/table.json'
    params = {'content': 'devices',
              'columns': 'objid,device',
              'filter_name': '@sub(' + self.hostname + ')'}
    params.update(self.params)
    try:
      REQ = json.loads(requests.get(URL+API,params=params).text)
    except requests.exceptions.RequestException as e:
      raise SystemExit(e)
    except ValueError as ejson:
      raise SystemExit(ejson)
    for i in list(REQ['devices']):
      self.deviceId.append(i['objid'])
    return self.deviceId

  def pauseDevice(self, switch = 'up'):
    API = '/api/pause.htm'
    action = 1
    if switch != 'up':
      action = 0
    for i in self.deviceId:
      params = {'id': i,
                'pausemsg': 'Pause sensor cause Deploy by devops',
                'action': action} # 0: pause, 1: resume
      params.update(self.params)
    try:
      REQ = requests.get(URL+API,params=params)
      print("PRTG device {} {} successful. PRTG API {}".format(sys.argv[1],switch,REQ))
      return REQ
    except UnboundLocalError as e:
      print("PRTG not found device name {}".format(sys.argv[1]))
      sys.exit(1)

if __name__=="__main__":
  try:
    dest = PrtgAPI(auth, URL, sys.argv[1])
    dest.searchByDevice()
    dest.pauseDevice(sys.argv[2])
  except IndexError as e:
    print("""
    Usage: pause_prtg.py DEVICE_NAME [OPTION]
    
    DEVICE_NAME: (case-sensitive)
    OPTION:
        up    - Resume PRTG device (default)
        down  - Pause PRTG device
    """)

  sys.exit(0)
