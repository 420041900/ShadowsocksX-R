#!/bin/sh

#  cow.sh
#  ShadowsocksX-R
#
#  Created by 称一称 on 16/8/12.
#  Copyright © 2016年 qiuyuzhou. All rights reserved.

name=cow

start(){
launchctl load "$HOME/Library/LaunchAgents/com.yicheng.ShadowsocksX-R.cow.plist"

}

stop(){
launchctl unload "$HOME/Library/LaunchAgents/com.yicheng.ShadowsocksX-R.cow.plist"

}



case "$1" in
'start')
    start
    ;;
'stop')
    stop
    ;;

'restart')
    stop
    start
    RETVAL=$?
    ;;
*)
    echo "Usage: $0 { start | stop | restart | status }"
    RETVAL=1
    ;;
esac
exit $RETVAL