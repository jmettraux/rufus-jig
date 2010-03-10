#!/bin/bash

echo
echo "================================================================================"
echo "ruby test/ut_7_http_get_timeout.rb -- --patron"
ruby -v
echo
ruby test/ut_7_http_get_timeout.rb -- --patron

echo
echo "================================================================================"
echo "ruby test/ut_7_http_get_timeout.rb -- --net"
ruby -v
echo
ruby test/ut_7_http_get_timeout.rb -- --net

echo
echo "================================================================================"
echo "ruby test/ut_7_http_get_timeout.rb -- --em"
ruby -v
echo
ruby test/ut_7_http_get_timeout.rb -- --em

echo

