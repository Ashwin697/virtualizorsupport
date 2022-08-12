#!/bin/bash

#color

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
clean='\033[0m'

function requirement {

	clear

	echo "------------------------------------------------------"
	echo -e "\tPlease Check all requirement"
	echo "------------------------------------------------------"

	echo "------------->> Check OS Version <<-------------------"
	cat /etc/os-release
	echo "   "
	echo "------------->> Check Kernel Release <<---------------"
	uname -r

	echo "   "
	if [ -e "/usr/bin/sestatus" ]; then
	echo "-------------->> Check Selinux Status <<--------------"
	sestatus
	fi

	echo "     "
	echo "-------------->> Check Architecture <<----------------"
	lscpu | grep Architecture
	echo "    "
	echo "--------------->> Check Virtualization <<-------------"
	virtcheck=`lscpu | grep Virtualization`
	if [ $? -ne 0 ]; then
		echo -e "${red}Virtualization not enabled..${clean}"

	else
		lscpu | grep Virtualization
		echo -e "${green}Virtualization is enabled..${clean}"
	fi
	echo "   "

        hyper=`lscpu | grep Hypervisor`
	if [ $? -eq 0 ]; then
		echo "------------->> Check Hypervisor <<-----------------"
		lscpu | grep Hypervisor
	fi

	typevirt=`lscpu | grep "Virtualization type"`
	if [ $? -eq 0 ]; then
		echo "--------------->> Check Virtualization type <<--------------"
		lscpu | grep "Virtualization type"
	fi
	echo "    "

	echo "-------------------------------------------------------"
	echo -e "\tCheck Partition Scheme"
	echo "-------------------------------------------------------"
	df -Th

	echo "      "
	echo "---------------->> check Disks on Server <<------------"
	lsblk
	echo "    "

	echo "------------->> Check Bridge On Server <<--------------"
	brctl show


}




function firewallcheck {
	clear

	echo "--------------------------------------------------------"
	echo -e "\tChecking Firewall restriction's"
	echo "--------------------------------------------------------"
       

       firwalldcheck="/usr/bin/firewall-cmd"
	if [ -e $firewalldcheck ]; then 
	        inactivestatus=$(service firewalld status |awk '{print $2}'| grep ^inactive)
                if [ "$inactivestatus" == "inactive" ]; then
                        echo -e "${red}firewalld is inactive.....${clean}"
	        else
                        echo -e  "${green}firewalld is active......${clean}"
	                echo -e  "${yellow}checking for allowed ports 4081-4085 , 5900-6000${clean} "
	                portcheck=`firewall-cmd --list-all |grep 5900-6000 | grep 4081-4085`

	                if [ $? -ne 0 ]; then

		        	 echo -e "${red}Port is not allowed for VNC and Panel${clean}"
			         echo -e "${yellow}Adding port for VNC and Panel.....${clean}"
			         panelport=`firewall-cmd --zone=public --permanent --add-port=4081-4085/tcp`
                                 vncport=`firewall-cmd --zone=public --permanent --add-port=5900-6000/tcp`
                                 reloadf=`firewall-cmd --reload`
			         echo -e "${green}Port for VNC and Panel is added to firewall...${clean}"

	                 else

                                 echo -e "${green}Port is allowed for VNC and Panel...${clean}"
		         fi
                 fi
	fi
 





        iptablecheck="/usr/sbin/iptables"
	echo "   "
	echo -e "${yellow}Note :: before adding iptable's rule, Please check if any rule exist's or not"
	echo -e  "\tif not then it's not recommended"
	echo -e "\tcheck below for existing iptable rule's${clean}"
	echo "  "
	echo "-----------------------------------------------"
	echo -e "\tiptables rule's"
	echo "-----------------------------------------------"
	echo "  "
	iptables -L
	echo "  "
	echo "-----------------------------------------------"
	if [ -e $iptablecheck ]; then
		iprule=`iptables -L | grep 4081:4085`
		if [ $? -eq 0 ]; then
			echo "  "
			echo -e "${green}Panel Port Already added to iptables${clean}"
		else
			echo "   "
			echo -e "${red}Panel Port not added to iptable rule, try this...${clean}"
			echo -e "----> ${yellow} iptables -I INPUT 1 -p tcp -m tcp --dport 4081:4085 -j ACCEPT${clean}"
			echo -e "${green}please run this command to add Panel Port on iptables rule's${clean}"
		fi

		iprulevnc=`iptables -L | grep 5900:6000`
		if [ $? -eq 0 ]; then
			echo " "
			echo -e "${green}VNC Port already added to iptables${clean}"
		else
			echo "  "
			echo -e "${red}VNC Port not added to iptable rule, try this.....${clean}"
			echo -e "----> ${yellow} iptables -I INPUT 2 -p tcp -m tcp --dport 5900:6000 -j ACCEPT${clean}"
			echo -e "${green}please run this command to add VNC Port on iptable rule's${clean}"
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
	echo -e "${yellow}Try to kill websocify if it's running on python3 and then start VNC again and check if this work...${clean}"

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
			echo -e "${green}Python installed${clean}"
		else
			echo "-------------->> Python2 not installed <<-----------------"
		        echo -e "\t${yellow}Please install Python2${clean}"
			
		fi	
		echo -e "${red}Python symlink not exist${clean}"
		echo -e "${yellow}Creating symlink for python....${clean}"
		symlinkpython=`ln -sf /usr/bin/python2 /usr/bin/python`
		echo -e  "${green}symlink created${clean}"
		ls -l /usr/bin/python
	fi
	echo "     "

	echo "----------------------------------------------------------------------------"
	echo -e "\tChecking Panel Settings novnc, master only , use server hostname"
	echo "----------------------------------------------------------------------------"

	echo "    "
	echo "----------------->> Master Proxy only <<----------------"
	if [ $masteronly -eq 1 ]; then
		echo -e "${green}'Master Proxy only' is enable on Panel${clean}"
	else
		echo -e "${yellow}Please enable it from Panel >> Configurations >> Master Settings >> noVNCsettings${clean}"
		echo "Master Proxy only"

	fi

	echo "     "
	echo "----------------->> Use Server Hostname <<-------------"
	if [ $servername -eq 1 ]; then
		echo -e "${green}'Use Server Hostname' is enabled on Panel${clean}"
	else
		echo -e "${yellow}Please enable it from Panel >> Configurations >> Master Settings >> noVNCsettings${clean}"
		echo "Use Server Hostname"

	fi

	echo "   "
        echo "-------------->> Enable noVNC <<-----------------------"
	if [ $enablevnc -eq 1 ]; then
		echo -e "${green}'Enable noVNC' is enabled on Panel${clean}"
	else
		echo -e "${yellow}Please enable it from Panel >> Configurations >> Master Settings >> noVNCsettings${clean}"
		echo "Enable noVNC"
	fi





}



function menu {
	clear
	echo	
	echo -e "\t\t\tVirtualizor Support Check menu"
	echo "     "
	echo -e "\t1. Check installation Requirements"
	echo -e "\t2. Check VNC issue"
	echo -e "\t3. Check Firewall restriction's"
	echo -e "\t0. Exit Program\n\n"
	echo -en "\t\tEnter Option: "
	read -n 1 option 
}

if [ "$(id -u)" != "0" ]; then
   echo -e "${red}This script must be run as root${clean}" 1>&2
   exit 1
fi

function main {

        while true
        do
	           menu
	           case $option in
		        0)
			        clear
			        break ;;
		        1)
			        requirement ;;
	         	2)
		        	checkvnc ;;
	        	3)
		        	clear
		        	firewallcheck ;;
	        	*)
		                clear
	         		echo "sorry, wrong selection";;
	        	esac

	        	echo -en "\n\n\t\t\tHit any key to continue"
	        	read -n 1 line
        	done
	}

virtualizorcheck="/usr/local/virtualizor"
if [ -d $virtualizorcheck ];then
	main

else
	echo -e "${red}Virtualizor is not installed on this system${clean}"
fi
