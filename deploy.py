import os
import boto3
from utility import scandir
from pystackpath import Stackpath
from os import environ as env
import pelican

PUBLIC_DIR = os.path.abspath('output')
PELICAN_CONF = os.path.abspath('pelicanconf.py')

print(PUBLIC_DIR, PELICAN_CONF)
print(env['test_var'])
##Function to recursively upload files in a given dir tree.
def upload_site(s3_client, bucket, dir_tree):
    for node in dir_tree:
        item = dir_tree[node]
        type = item["type"]
        if "file" in type:
            ##Upload the file.
            src = item["abs_path"]
            dest = item["upload_path"]
            print(f"Uploading {dest}")
            s3_client.upload_file(src, bucket, dest)
        elif "dir" in type:
            sub_tree = item["dir_list"]
            upload_site(s3_client, bucket, sub_tree)

def purge_cache():
    client_id, api_secret, stack_id = load_api_settings()
    sp = Stackpath(client_id, api_secret)
    response = sp.stacks().get(stack_id).purge([{"url": "https://danielsteinke.com/",}])

    print(response)

def load_os_settings():
    try:
        OS_KEY, OS_SECRET, BUCKET = env["ds_os_key"], env["ds_os_secret"], env["ds_os_bucket"]
        return (OS_KEY, OS_SECRET, BUCKET)
    except (IOError, ValueError) as e:
        print("Unable to OS load secrets!")
        print(e)
        exit(code=1)

def load_api_settings():
    try:
        API_KEY, API_SECRET, STACK_ID = env["ds_api_key"], env["ds_api_secret"], env["ds_stack_id"]
        return (API_KEY, API_SECRET, STACK_ID)
    except (IOError, ValueError) as e:
        print("Unable to load SP API secrets!")
        print(e)
        exit(code=1)

if __name__ == '__main__':

    KEY, SECRET, BUCKET = load_os_settings()

    pelican_settings = pelican.read_settings(PELICAN_CONF,override={
            'THEME_STATIC_PATHS': ['theme']
})


    pelican_build = pelican.Pelican(pelican_settings)
    pelican_build.run()

    session = boto3.session.Session()
    public_dir_tree = scandir(PUBLIC_DIR)

    s3_client = session.client( service_name='s3', aws_access_key_id=KEY, aws_secret_access_key=SECRET, endpoint_url='https://s3.us-east.stackpathstorage.com',)

    upload_site(s3_client, BUCKET, public_dir_tree)
    purge_cache()
