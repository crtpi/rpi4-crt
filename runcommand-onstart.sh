# Slightly modified from : https://github.com/Sakitoshi/retropie-crt-tvout/blob/master/to_configs/all/runcommand-onstart.sh
# Further modified from : https://github.com/b0xspread/rpi4-crt/blob/master/runcommand-onstart.sh

#If Value found in 480i.txt for Consoles
if [ -f "/opt/retropie/configs/$1/480i.txt" ]; 
	then interlaced=$(tr -d "\r" < "/opt/retropie/configs/$1/480i.txt" | sed -e 's/\[/\\\[/'); 
fi > /dev/null
#If Value found in 480i.txt for Ports
if [ -f "/opt/retropie/configs/ports/$1/480i.txt" ]; 
	then interlaced=$(tr -d "\r" < "/opt/retropie/configs/ports/$1/480i.txt" | sed -e 's/\[/\\\[/'); 
fi > /dev/null
# If 480i.txt is Empty
if [ ! -s "/opt/retropie/configs/$1/480i.txt" ] && [ ! -s "/opt/retropie/configs/ports/$1/480i.txt" ] || [ -z "$interlaced" ]; 
	then interlaced="empty"; 
fi > /dev/null
#If Value found in 240p.txt for Consoles
if [ -f "/opt/retropie/configs/$1/240p.txt" ]; 
	then progresive=$(tr -d "\r" < "/opt/retropie/configs/$1/240p.txt" | sed -e 's/\[/\\\[/'); 
fi > /dev/null
#If Value found in 240p.txt for Ports
if [ -f "/opt/retropie/configs/ports/$1/240p.txt" ]; 
	then progresive=$(tr -d "\r" < "/opt/retropie/configs/ports/$1/240p.txt" | sed -e 's/\[/\\\[/'); 
fi > /dev/null
# If 240p.txt is Empty
if [ ! -s "/opt/retropie/configs/$1/240p.txt" ] && [ ! -s "/opt/retropie/configs/ports/$1/240p.txt" ] || [ -z "$progresive" ]; 
	then progresive="empty"; 
fi > /dev/null

#Execute Script
if tvservice -s | grep -q NTSC && { ! echo "$3" | grep -q -wi "$interlaced" || echo "$interlaced" | grep -q empty; } && ! echo "$interlaced" | grep -q -xi "all" && { echo "$3" | grep -q -wi "$progresive" || echo "$progresive" | grep -q empty; }; 
	then echo 'NTSC 4:3 P' > /opt/retropie/configs/all/desired_mode/value; 
	else echo 'NTSC 4:3' > /opt/retropie/configs/all/desired_mode/value;   
fi > /dev/null
# Report Out / Quiet
echo "runcommand-onstart $1 $2 $3" > /dev/null
