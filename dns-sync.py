import requests
import json
import sys
import re

#Args order:
# api_key api_secret shopper_id target_domain ns_data
api_key = sys.argv[1]
api_secret =  sys.argv[2]
auth_header = {"Authorization": f"sso-key {api_key}:{api_secret}", "accept": "application/json" }
print(f"Auth header: {auth_header}")

godaddy_shopper_id =  sys.argv[3]
target_domain =  sys.argv[4]

ns_string = sys.argv[5]
##Strip out TLD full stops, which GoDaddy doesn't like.
## This is the expected format of the input string: '["ns1-38.azure-dns.com.","ns2-38.azure-dns.net.","ns3-38.azure-dns.org.","ns4-38.azure-dns.info."]'
ns_string = re.sub("\.,", "\",\"", ns_string)
#I hate mangling strings!
#TODO: FIXME
ns_string = re.sub("\[", "[\"", ns_string)
ns_string = re.sub("\.\]","\"]", ns_string)
print(type(ns_string))
print(f"ns_string 2: {ns_string}")
request_body = { "nameServers": json.loads(ns_string) }
print(f"request body: {request_body}")

cid_request_url = f"https://api.godaddy.com/v1/shoppers/{godaddy_shopper_id}?includes=customerId"
cid_response_json = requests.get( cid_request_url, headers=auth_header).json()
print(f"cid response {cid_response_json}")

cid = cid_response_json.get("customerId")

put_nameserver_url = f"https://api.godaddy.com/v2/customers/{cid}/domains/{target_domain}/nameServers"
print(f"name server url: {put_nameserver_url}")
put_nameserver_response = requests.put( put_nameserver_url, headers=auth_header, json=request_body)
print(put_nameserver_response)
