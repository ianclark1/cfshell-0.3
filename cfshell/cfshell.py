#! /usr/bin/env python
'''
Created on Oct 6, 2009

@author: oarevalo
'''
import urllib
import urllib2
import cookielib
import string
import sys
from optparse import OptionParser
try:
    import readline
except ImportError, e:
    pass


version = '0.3'
defaultHost = 'http://localhost/cfshell'
cfshellPath = 'cfshell.cfm'
prompt = ">> "

def getOpener():
    cj = cookielib.CookieJar()

    try:
        opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
        resp = opener.open(shellPath)
        cj.extract_cookies(resp, urllib2.Request(shellPath))

    except urllib2.URLError, e:
        print 'Connection error:',e
        sys.exit(-1)
    
    return opener

def execute(opener, userInput):
    try:
        if(userInput=='.exit'):
            return False
        
        elif(string.split(userInput)[0]=='.get'):
            if(len(string.split(userInput))>1 ):
                getPath = options.path + string.split(userInput)[1]
                if(options.verbose): print('GET ' + getPath)
                response = opener.open(getPath)
                print response.code
            else:
                print("Usage: .get <template_path>")

        elif(string.split(userInput)[0]=='.sget'):
            if(len(string.split(userInput))>1 ):
                getPath = options.path + string.split(userInput)[1]
                if(options.verbose): print('GET ' + getPath)
                response = opener.open(getPath)
                html = response.read()
                print html.strip()
            else:
                print("Usage: .sget <template_path>")

        elif(string.split(userInput)[0]=='.post'):
            if(len(string.split(userInput))>1 ):
                getPath = options.path + string.split(userInput)[1]
                if(options.verbose): print('POST ' + getPath)
                if(len(string.split(userInput))>2):
                    data = urllib.urlencode(eval(string.split(userInput)[2]))
                    if(options.verbose): print('data: ' + data)
                else:
                    data = ""
                response = opener.open(getPath,data)
                print response.code
            else:
                print("Usage: .post <template_path> [<args>]")

        elif(string.split(userInput)[0]=='.spost'):
            if(len(string.split(userInput))>1 ):
                getPath = options.path + string.split(userInput)[1]
                if(options.verbose): print('POST ' + getPath)
                data = urllib.urlencode(eval(string.split(userInput)[2]))
                if(options.verbose): print('data: ' + data)
                response = opener.open(getPath,data)
                html = response.read()
                print html.strip()
            else:
                print("Usage: .spost <template_path> [<args>]")

        else:
            try:
                data = urllib.urlencode({'_cmd' : userInput})
                response = opener.open(shellPath,data)
                html = response.read()
                print html.strip()
            except urllib2.HTTPError, e:
                print '[' + str(e.code) + '] ' + e.read().strip()

    except urllib2.HTTPError, e:
        print '[' + str(e.code) + '] '
 
    return True
    

if __name__ == '__main__':

    parser = OptionParser()
    parser.add_option("-p", "--path", dest="path", default="http://localhost/cfshell/",
                      help="Sets the target host and path where to connect", metavar="FILE")
    parser.add_option("-q", "--quiet",
                      action="store_false", dest="verbose", default=True,
                      help="don't print status messages to stdout")
    parser.add_option("-i", "--input",
                     dest="input", default="",
                     help="Provides an expression or command to send to the server")
    parser.add_option("-f", "--file",
                      dest="inputFile", default="",
                      help="Processes the contents of the given file as CFML statements")   
       
    (options, args) = parser.parse_args()


    # define url of target server
    shellPath = options.path + cfshellPath

    # check for connection
    opener = getOpener()
    
    # welcome message
    if(options.verbose):
        print('CFShellClient :: Version ' + version)     
        print('URL: ' + options.path)     
        print('Type .help for available commands')

    if(options.input!=""):
        userInput = options.input  
        exitAfterInput = True  
        
    elif(options.inputFile!=""):
        f = open(options.inputFile,"r")
        userInput = f.read()
        exitAfterInput = True  
    else:
        userInput = ""
        exitAfterInput = False  
        
    # main loop
    while True:
        if(userInput!=""):
            if(execute(opener, userInput)==False):
                break;
        
        if(exitAfterInput): break;
        
        userInput = raw_input(prompt)
       
    if(options.verbose): print('Bye!')    
            
    pass


