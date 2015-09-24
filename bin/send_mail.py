#!/usr/bin/python

from email.header import Header
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib, sys, os, urllib

def containsnonasciicharacters(str):
    return not all(ord(c) < 128 for c in str)

def addheader(message, headername, headervalue):
    if containsnonasciicharacters(headervalue):
        h = Header(headervalue, 'utf-8')
        message[headername] = h
    else:
        message[headername] = headervalue
    return message

def main(argv=sys.argv):
    if len(argv) <= 1 or not os.path.isfile(argv[1]):
        print "need one filename as attachment"
        return 1

    subfix=os.path.splitext(argv[1])[-1]
    msg = MIMEMultipart()

    try:
        fp = open(argv[1], 'rb')
        att1 = MIMEText(fp.read(), 'base64', 'utf-8')
        fp.close()
    except Exception, e:
        print 'error when create attachment: ' + str(e)
        return 1

    att1["Content-Type"] = 'application/octet-stream'
    basefile=os.path.basename(argv[1])
    att1["Content-Disposition"] = 'attachment; filename*=UTF-8\'\'%s' % urllib.quote(basefile)
    msg.attach(att1)

    msg["Accept-Language"]="zh-CN"
    msg["Accept-Charset"]="ISO-8859-1,utf-8"
    #msg['to'] = 'crazyman@foxmail.com'
    msg['to'] = 'crazyman80@kindle.cn'
    msg['from'] = 'dengwei98406@163.com'
    if subfix == ".mobi":
        subject = 'send file <%s>' % urllib.quote(basefile)
    else:
        subject = 'Convert'
    msg = addheader(msg, 'subject', subject)

    print "subject: %s, filename: %s" % (msg['subject'], os.path.basename(argv[1]))

    try:
        server = smtplib.SMTP('smtp.163.com')
        #server.ehlo()
        #server.starttls()
        #server.ehlo()
        server.login('dengwei98406@163.com','torrent')
        server.sendmail(msg['from'], msg['to'], msg.as_string())
        #server.quit()
        server.close()
        print "OK"

        return 0
    except Exception, e:
        print 'error when send file: ' + str(e)
        return 1

if __name__ == "__main__":
    exit(main())
