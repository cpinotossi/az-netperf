 #!/bin/sh
echo "Updating packages ..."
sudo apt-get -qq update
echo "Install netperf ..."
sudo apt-get -qq install netperf
echo "kill netperf ..."
sudo killall -9 netserver
echo "Start netperf in deamon mode ..."
sudo netserver -d -p 12865 -4 -v 2 -Z 0+01tdTzPwjcIFM/sphtJQ==
