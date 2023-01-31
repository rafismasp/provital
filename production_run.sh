#!/bin/bash

#thin -e production -p 6001 -s 8 -P tmp/pids/prod.pid -d $1

if [ "$1" = "start" ]; then
#  unicorn -c config/unicorn.rb -E "production" -D
# unicorn -c config/unicorn.rb -D
  puma -d
#  bundle exec pumactl -P -d tmp/pids/puma.pid start
fi

if [ "$1" = "stop" ]; then
  #kill -9 `cat tmp/pids/unicorn.pid`
  #kill -9 `cat tmp/pids/puma.pid`
  bundle exec pumactl -P tmp/pids/puma.pid stop
fi

if [ "$1" = "restart" ]; then
  bundle exec pumactl -P tmp/pids/puma.pid restart
fi


