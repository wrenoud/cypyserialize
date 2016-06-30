from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension

NAME = "cypyserialize"
VERSION = "0.3"
DESCR = "Really easy, really quick, binary parser framework for Python"
try:
   import pypandoc
   LONG_DESC = pypandoc.convert('README.md', 'rst')
except (IOError, ImportError):
   LONG_DESC = open('README.md').read()

URL = "https://github.com/wrenoud/cypyserialize"
DOWNLOAD_URL = "https://github.com/wrenoud/cypyserialize/tarball/" + VERSION

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


setup(
    name=NAME,
    packages=PACKAGES,
    version=VERSION,
    description=DESCR,
    long_description=LONG_DESC,
    author=AUTHOR,
    author_email=EMAIL,
    url=URL,
    download_url=DOWNLOAD_URL,
    keywords=['testing', 'logging', 'example'],  # arbitrary keywords
    classifiers=[],
    license=LICENSE,
    ext_modules=cythonize(EXTENSIONS),
    install_requires=REQUIRES,
)
