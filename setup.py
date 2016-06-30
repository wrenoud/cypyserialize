from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension

NAME = "cypyserialize"
VERSION = "0.1"
DESCR = ""
URL = "http://www.google.com"

AUTHOR = "Weston Renoud"
EMAIL = "wrenoud@gmail.com"

LICENSE = "Apache 2.0"

SRC_DIR = NAME
PACKAGES = [SRC_DIR]

EXTENSIONS = [
	Extension(
		SRC_DIR + ".variant",
		[SRC_DIR + '/variant.pyx'],
		libraries=[]
	),
	Extension(
		SRC_DIR + ".serializers",
		[SRC_DIR + '/serializers.pyx'],
		libraries=[]
	),
	Extension(
		SRC_DIR + ".serializable",
		[SRC_DIR + '/serializable.pyx'],
		libraries=[]
	)
]

REQUIRES = []
PACKAGES = ["src"]

setup(
    install_requires = REQUIRES,
	packages = PACKAGES,
	zip_safe = False,
	name = NAME,
	version = VERSION,
	description=DESCR,
	author=AUTHOR,
	author_email=EMAIL,
	url=URL,
	license=LICENSE,
	ext_modules = cythonize(EXTENSIONS)
)
