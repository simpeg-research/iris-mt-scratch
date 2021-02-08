#!/usr/bin/env python
"""
A setuptools based setup module.
See:
https://packaging.python.org/guides/distributing-packages-using-setuptools/
https://github.com/pypa/sampleprojecta

"""

# Always prefer setuptools over distutils
from setuptools import setup, find_packages

setup(
    author="MTH5 Team",
    author_email="kappler@cal.berkeley.eduu",
    python_requires=">=3.6",
    classifiers=[
        "Development Status :: 2 - Pre-Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Natural Language :: English",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
    ],
    name='iris_mt_scratch',
    version='0.0.0', 
    description='A place to keep prototypes and experiements while developing mth5, not intended for release',
    url='https://github.com/simpeg-research/iris-mt-scratch',
    keywords='mth5, sandbox',
    packages=find_packages(include=['iris_mt_scratch', 'iris_mt_scratch.*']),  # Required
) 

