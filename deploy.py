import os
import boto3
from utility import scandir
from pystackpath import Stackpath
import pelican

SECRETS_FILE_OS = os.path.abspath('.os_secrets')
SECRETS_FILE_API = os.path.abspath('.api_secrets')
PUBLIC_DIR = os.path.abspath('output')
PELICAN_CONF = os.path.abspath('pelicanconf.py')

print(PUBLIC_DIR, PELICAN_CONF, SECRETS_FILE_API, SECRETS_FILE_OS)

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
    response = sp.stacks().get(stack_id).cdnsites().purge("https://danielsteinke.com/")

    print(response)

def load_os_settings():
    try:
        OS_KEY, OS_SECRET, BUCKET = open(SECRETS_FILE_OS, "r").read().splitlines()
        return (OS_KEY, OS_SECRET, BUCKET)
    except (IOError, ValueError) as e:
        print("Unable to load secrets!")
        print("The object storage key, object storage secret and bucket name should be placed in a file called \".os_secrets\" respectively listed on the first, second and third lines.")
        print(e)
        exit(code=1)

def load_api_settings():
    try:
        API_KEY, API_SECRET, STACK_ID = open(SECRETS_FILE_API, "r").read().splitlines()
        return (API_KEY, API_SECRET, STACK_ID)
    except (IOError, ValueError) as e:
        print("Unable to load secrets!")
        print("The API key, API secret, stack ID should be placed in a file called \".os_secrets\" respectively listed on the first, second and third lines.")
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
