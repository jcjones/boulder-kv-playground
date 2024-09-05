$ports=@(2379,2380,2381,2382,2383,2384,3000,3306,3307,3308,9090,20160,20161,20162) # the ports you want to open
$addr='0.0.0.0';

$wslIP = bash.exe -c "hostname -I"
$found = $wslIP -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

if(! $wslIP -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {
  echo "WSL's IP cannot be found. Aborting";
  exit;
}

for ($i = 0; $i -lt $ports.length; $i++) {
  $port = $ports[$i];
  echo "Deleting port $port"
  iex "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$addr";
  echo "Forwarding port $port to $wslIP"
  iex "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$wslIP";
}
