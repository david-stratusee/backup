#!/usr/bin/python

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib, sys, os

def main(argv=sys.argv):
    if len(argv) <= 1 or not os.path.isfile(argv[1]):
        print "need one filename as attachment"
        return 1

    subfix=os.path.splitext(argv[1])[-1]
    msg = MIMEMultipart()

    try:
        fp = open(argv[1], 'rb')
        att1 = MIMEText(fp.read(), 'base64', 'gb2312')
        fp.close()
    except Exception, e:
        print 'error when create attachment: ' + str(e)
        return 1

    att1["Content-Type"] = 'application/octet-stream'
    att1["Content-Disposition"] = 'attachment; filename=%s' % os.path.basename(argv[1])
    msg.attach(att1)

    msg['to'] = 'crazyman80@kindle.cn'
    msg['from'] = 'dengwei98406@163.com'
    if subfix == ".mobi":
        msg['subject'] = 'send file %s' % argv[1]
    else:
        msg['subject'] = 'Convert'
    print msg['subject']

    try:
        server = smtplib.SMTP('smtp.163.com')
        #server.ehlo()
        #server.starttls()
        #server.ehlo()
        server.login('dengwei98406@163.com','torrent')
        server.sendmail(msg['from'], msg['to'], msg.as_string())
        server.quit()
        print "OK"

        return 0
    except Exception, e:
        print 'error when send file: ' + str(e)
        return 1

if __name__ == "__main__":
    exit(main())
