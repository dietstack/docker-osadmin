#!/usr/bin/python
import os,netifaces

print(netifaces.ifaddresses(os.environ['DATA_INTERFACE']))[netifaces.AF_INET][0]['addr']
