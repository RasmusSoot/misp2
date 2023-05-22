#!/bin/bash
find /var/lib/tomcat9/webapps/misp2/xforms-jsp/ -type f -cmin +600 -exec rm {} \;