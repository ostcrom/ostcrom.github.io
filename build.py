import os
import boto3
from utility import scandir
from pystackpath import Stackpath
from os import environ as env
import pelican

PUBLIC_DIR = os.path.abspath('output')
PELICAN_CONF = os.path.abspath('pelicanconf.py')
CONTENT_DIR = os.path.abspath('content')
THEME_DIR = os.path.abspath('theme')

print(f"Public dir: {PUBLIC_DIR}, Pelican conf: {PELICAN_CONF}, Content: {CONTENT_DIR}, THEME_DIR {THEME_DIR}")


if __name__ == '__main__':

    pelican_settings = pelican.read_settings(PELICAN_CONF,override={
            'THEME': THEME_DIR,
            'THEME_STATIC_PATHS': [THEME_DIR],
            'PATH': CONTENT_DIR
})

    pelican_build = pelican.Pelican(pelican_settings)
    pelican_build.run()

