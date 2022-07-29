#!/bin/bash


function firewallcheck {
	clear

	echo "--------------------------------------------------------"
	echo -e "\tChecking Firewall restriction's"
	echo "--------------------------------------------------------"

	inactivestatus=$(service firewalld status |awk '{print $2}'| grep ^inactive)
        if [ "$inactivestatus" == "inactive" ]; then
            echo "firewalld is inactive....."
	else
               echo "firewalld is active......"
	       echo "checking for allowed ports 4081-4085 , 5900-6000 "
	       portcheck=`firewall-cmd --list-all |grep 5900-6000 | grep 4081-4085`

	         if [ $? -ne 0 ]; then

			 echo "Port is not allowed for VNC and Panel"
			 echo "Adding port for VNC and Panel....."
			 panelport=`firewall-cmd --zone=public --permanent --add-port=4081-4085/tcp`
                         vncport=`firewall-cmd --zone=public --permanent --add-port=5900-6000/tcp`
                         reloadf=`firewall-cmd --reload`
			 echo "Port for VNC and Panel is added to firewall.."

	         else

                     echo "Port is allowed for VNC and Panel..."
		 fi

		 
               fi
}



function checkvnc {
	clear
	masteronly=$(cat /usr/local/virtualizor/universal.php | grep -m2  novnc | tail -n1 | awk -F= '{print $2}' | awk -F ";" '{print $1}')
        servername=$(cat /usr/local/virtualizor/universal.php | grep  novnc | tail -n1 | awk -F= '{print $2}' | awk -F ";" '{print $1}')
        enablevnc=$(cat /usr/local/virtualizor/universal.php | grep -m1  novnc | awk -F= '{print $2}' | awk -F ";" '{print $1}')

        firewallcheck
	echo "         "
	echo "         "
	echo "-----------------------------------------------------------"
	echo -e "\tChecking websockify status.."
	echo "-----------------------------------------------------------"
	ps -aux | grep -E "(websockify -D :4081 --target-config=/usr/local/virtualizor/conf/novnc.vnc --web)"
	echo "-----------------------------------------------------------"
	echo "Try to kill websocify once and then start VNC again and check if this work.."

	echo "                "
	echo "                "


	## checking symlink for python
	echo "-----------------------------------------------------"
	echo -e "\tChecking fot Python symlink"
	echo "-----------------------------------------------------"
	pythoncheck="/usr/bin/python"
	python2check="/usr/bin/python2"
	if [ -e $pythoncheck ]; then
		echo "----->>Python symlink is exist please check it's size<<------"
		ls -l /usr/bin/python
	else
		if [ -e  $python2check ]; then
			echo "Python installed"
		else
			echo "Python2 not installed"
		        echo "Installing Python2"
			echo "---------------------------------------------"
			
		fi	
		echo "Python symlink not exist"
		echo "Creating symlink for python...."
		symlinkpython=`ln -sf /usr/bin/python2 /usr/bin/python`
		echo "symlink created"
		ls -l /usr/bin/python
	fi
	echo "     "

	echo "----------------------------------------------------------------------------"
	echo -e "\tChecking Panel Settings novnc, master only , use server hostname"
	echo "----------------------------------------------------------------------------"

	echo "    "
	echo "----------------->> Master Proxy only <<----------------"
	if [ $masteronly -eq 1 ]; then
		echo "'Master Proxy only' is enable on Panel"
	else
		echo "Please enable it from Panel >> Configurations >> Master Settings >> noVNCsettings"
		echo "Master Proxy only"

	fi

	echo "     "
	echo "----------------->> Use Server Hostname <<-------------"
	if [ $servername -eq 1 ]; then
		echo "'Use Server Hostname' is enabled on Panel"
	else
		echo "Please enable it from Panel >> Configurations >> Master Settings >> noVNCsettings"
		echo "Use Server Hostname"

	fi

	echo "   "
        echo "-------------->> Enable noVNC <<-----------------------"
	if [ $enablevnc -eq 1 ]; then
		echo "'Enable noVNC' is enabled on Panel"
	else
		echo "Please enable it from Panel >> Configurations >> Master Settings >> noVNCsettings"
		echo "Enable noVNC"
	fi





}



function menu {
	clear
	echo	
	echo -e "\t\t\tVirtualizor Support Check menu"
	echo -e "\t1. Check VNC issue"
	echo -e "\t2. Check Firewall restriction's"
	echo -e "\t0. Exit Program\n\n"
	echo -en "\t\tEnter Option: "
	read -n 1 option 
}

while true
do
	menu
	case $option in
		0)
			clear
			break ;;
		1)
			checkvnc ;;
		2)
			clear
			firewallcheck ;;
		*)
			clear
			echo "sorry, wrong selection";;
		esac

		echo -en "\n\n\t\t\tHit any key to continue"
		read -n 1 line
	done

