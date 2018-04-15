##################################################
# Anything wrong? Find me via telegram: @CN_SZTL #
##################################################

#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
# Font colors
default_fontcolor="\033[0m"
red_fontcolor="\033[31m"
green_fontcolor="\033[32m"
# Background colors
green_backgroundcolor="\033[42;37m"
red_backgroundcolor="\033[41;37m"
# Fonts
error_font="${red_fontcolor}[Error]${default_fontcolor}"
ok_font="${green_fontcolor}[OK]${default_fontcolor}"
}

function check_os(){
	clear
	# Check root user
	echo -e "正在检测当前是否为ROOT用户..."
	if [[ $EUID -ne 0 ]]; then
		sudo su
		check_os
		clear
		echo -e "${error_font}当前并非ROOT用户，请先切换到ROOT用户后再使用本脚本。"
		exit 1
	else
		clear
		echo -e "${ok_font}检测到当前为Root用户。"
	fi
	# Check OS type
	clear
	echo -e "正在检测此OS是否被支持..."
	if [ ! -z "$(cat /etc/issue | grep Debian)" ];then
		OS='debian'
		clear
		echo -e "${ok_font}该脚本支持您的系统。"
	elif [ ! -z "$(cat /etc/issue | grep Ubuntu)" ];then
		OS='ubuntu'
		clear
		echo -e "${ok_font}该脚本支持您的系统。"
	elif [ -f /etc/redhat-release ];then
		OS='centos'
		clear
		echo -e "${ok_font}该脚本支持您的系统。"
	else
		clear
		echo -e "${error_font}目前暂不支持您使用的操作系统，请切换至CentOS/Debian/Ubuntu。"
		exit 1
	fi
}

function check_install_status(){
	sshd_pid=$(ps -ef |grep "sshd" |grep -v "grep" | grep -v "init.d" |grep -v "service" |awk '{print $2}')
	if [[ ${sshd_pid} = "" ]]; then
		sshd_status="${red_fontcolor}未运行${default_fontcolor}"
	else
		sshd_status="${green_fontcolor}正在运行${default_fontcolor}"
	fi
}

function load_configs(){
	ssh_publickey=$(cat ~/.ssh/authorized_keys)
	ssh_privatekey=$(cat ~/.ssh/private_keys)
	private_keys_password=$(cat ~/.ssh/private_keys_password)
	ssh_port=$(cat /etc/ssh/sshd_config | grep "Port " | awk -F "#" '{print $NF}' | awk -F "Port " '{print $NF}')
}

function echo_install_list(){
	clear
	echo -e "--------------------------------------------------------------------------------------------------
1.更改SSH登陆端口
2.配置Password登陆
3.配置PublicKey登录
--------------------------------------------------------------------------------------------------
SSH当前运行状态：${sshd_status}
SSH当前监听端口：${green_fontcolor}${ssh_port}${default_fontcolor}
4.重启SSH服务
--------------------------------------------------------------------------------------------------
5.更新脚本

6.查看PublicKey
7.查看PrivateKey
8.查看PrivateKey password
--------------------------------------------------------------------------------------------------"
	stty erase '^H' && read -p "请输入序号：" determine_type
	if [[ ${determine_type} = "" ]]; then
		clear
		echo -e "${error_font}请输入序号！"
		exit 1
	elif [[ ${determine_type} -lt 1 ]]; then
		clear
		echo -e "${error_font}请输入正确的序号！"
		exit 1
	elif [[ ${determine_type} -gt 8 ]]; then
		clear
		echo -e "${error_font}请输入正确的序号！"
		exit 1
	else
		data_processing
	fi
}

function data_processing(){
	clear
	echo -e "正在处理请求中..."
	if [[ ${determine_type} = "4" ]]; then
		restart_service
	elif [[ ${determine_type} = "5" ]]; then
		clear
		echo -e "正在更新脚本中..."
		filepath=$(cd "$(dirname "$0")"; pwd)
		filename=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
		curl -O https://raw.githubusercontent.com/1715173329/ssh-onekey/master/ssh-go.sh
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}脚本更新成功，脚本位置：\"${green_backgroundcolor}${filename}/ssh-go.sh${default_fontcolor}\"，使用：\"${green_backgroundcolor}bash ${filename}/ssh-go.sh${default_fontcolor}\"。"
		else
			clear
			echo -e "${error_font}脚本更新失败！"
		fi
	elif [[ ${determine_type} = "6" ]]; then
		prevent_see_publickey
	elif [[ ${determine_type} = "7" ]]; then
		prevent_see_privatekey
	elif [[ ${determine_type} = "8" ]]; then
		prevent_see_privatekey_password
	elif [[ ${determine_type} = "1" ]]; then
		ssh_port_linewords=$(cat /etc/ssh/sshd_config | grep "Port ")
		if [[ ${ssh_port_linewords} = "Port "${ssh_port} ]]; then
			clear
			echo -e "${ok_font}未检测到#号，正在执行下一步..."
		else
			sed -i "s/#Port/Port/g" "/etc/ssh/sshd_config"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}清除#号成功。"
			else
				clear
				echo -e "${error_font}清除#号失败！"
				exit 1
			fi
		fi
		generate_port
		stty erase '^H' && read -p "请输入SSH监听端口(默认：${default_ssh_new_listenport})：" ssh_new_listenport
		if [[ ${ssh_new_listenport} = "" ]]; then
			ssh_new_listenport=${default_ssh_new_listenport}
			open_port
			sed -i "s/${ssh_port}/${ssh_new_listenport}/g" "/etc/ssh/sshd_config"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置SSH端口成功。"
			else
				clear
				echo -e "${error_font}配置SSH端口失败！"
				exit 1
			fi
			close_port
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置SSH端口成功。"
			else
				clear
				echo -e "${error_font}配置SSH端口失败！"
				exit 1
			fi
			restart_service
			echo -e "${ok_font}原SSH监听端口：${red_backgroundcolor}${ssh_port}${default_fontcolor}"
			echo -e "${ok_font}现SSH监听端口：${green_backgroundcolor}${ssh_new_listenport}${default_fontcolor}"
		elif [[ ${ssh_new_listenport} -lt 1 ]]; then
			clear
			echo -e "${error_font}SSH端口输入错误！"
			exit 1
		elif [[ ${ssh_new_listenport} -gt 65535 ]]; then
			clear
			echo -e "${error_font}SSH端口输入错误！"
			exit 1
		else
			check_port
			open_port
			sed -i "s/${ssh_port}/${ssh_new_listenport}/g" "/etc/ssh/sshd_config"
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置SSH端口成功。"
			else
				clear
				echo -e "${error_font}配置SSH端口失败！"
				exit 1
			fi
			close_port
			restart_service
			clear
			echo -e "${ok_font}原SSH监听端口：${red_backgroundcolor}${ssh_port}${default_fontcolor}"
			echo -e "${ok_font}现SSH监听端口：${green_backgroundcolor}${ssh_new_listenport}${default_fontcolor}"
		fi
	elif [[ ${determine_type} = "2" ]]; then
		stty erase '^H' && read -p "请输入连接密码(默认：${default_ssh_key_password})：" ssh_connect_password
		if [[ ${ssh_connect_password} = "" ]]; then
			ssh_connect_password=${default_ssh_key_password}
			echo -e "${ok_font}处理成功。"
		else
			echo -e "${ok_font}处理成功。"
		fi
		passwd root<<-EOF
			${ssh_connect_password}
			${ssh_connect_password}
		EOF
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}设置密码成功。"
		else
			clear
			echo -e "${error_font}设置密码失败！"
			exit 1
		fi
		ssh_pubkey_linewords=$(cat /etc/ssh/sshd_config | grep "PubkeyAuthentication ")
		sed -i "s/${ssh_pubkey_linewords}/PubkeyAuthentication no/g" "/etc/ssh/sshd_config"
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}关闭公钥登陆成功。"
		else
			clear
			echo -e "${error_font}关闭公钥登陆失败！"
			exit 1
		fi
		ssh_password_linewords=$(cat /etc/ssh/sshd_config | grep "PasswordAuthentication ")
		sed -i "s/${ssh_password_linewords}/PasswordAuthentication yes/g" "/etc/ssh/sshd_config"
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}开启密码登陆成功。"
		else
			clear
			echo -e "${error_font}开启密码登陆失败！"
			exit 1
		fi
		rm -rf ~/.ssh
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除ssh文件夹成功。"
		else
			clear
			echo -e "${error_font}删除ssh文件夹失败！"
			exit 1
		fi
		clear
		echo -e "${ok_font}This is your SSH login password:\n${green_backgroundcolor}${ssh_connect_password}${default_fontcolor}"
	elif [[ ${determine_type} = "3" ]]; then
		stty erase '^H' && read -p "请输入私钥类型(默认：ecdsa，仅支持rsa和ecdsa)：" ssh_key_type
		if [[ ${ssh_key_type} = "" ]]; then
			ssh_key_type="ecdsa"
			clear
			echo -e "${ok_font}处理成功。"
		elif [[ ${ssh_key_type} = "ecdsa" ]]; then
			clear
			echo -e "${ok_font}处理成功。"
		elif [[ ${ssh_key_type} = "rsa" ]]; then
			clear
			echo -e "${ok_font}处理成功。"
		else
			clear
			echo -e "${error_font}密匙类型输入错误！"
			exit 1
		fi
		default_ssh_key_password=$(cat /proc/sys/kernel/random/uuid)
		stty erase '^H' && read -p "请输入私钥密码(默认：${default_ssh_key_password})：" ssh_key_password
		if [[ ${ssh_key_password} = "" ]]; then
			ssh_key_password=${default_ssh_key_password}
			echo -e "${ok_font}处理成功。"
			clear
		else
			echo -e "${ok_font}处理成功。"
		fi
		rm -rf ~/.ssh/
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}删除ssh文件夹成功。"
		else
			clear
			echo -e "${error_font}删除ssh文件夹失败！"
			exit 1
		fi
		mkdir ~/.ssh/
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}创建ssh文件夹成功。"
		else
			clear
			echo -e "${error_font}创建ssh文件夹失败！"
			exit 1
		fi
		echo -e "${ssh_key_password}" > ~/.ssh/private_keys_password
		if [[ ${ssh_key_type} = "ecdsa" ]]; then
			ssh-keygen -q -b 521 -t ecdsa -N ${ssh_key_password} -f ~/.ssh/private_keys
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}创建公私钥成功。"
			else
				clear
				echo -e "${error_font}创建公私钥失败！"
				exit 1
			fi
			mv ~/.ssh/private_keys.pub ~/.ssh/authorized_keys
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置公钥成功。"
			else
				clear
				echo -e "${error_font}配置公钥失败！"
				exit 1
			fi
		else
			ssh-keygen -q -b 4096 -t rsa -N ${ssh_key_password} -f ~/.ssh/private_keys
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}创建公私钥成功。"
			else
				clear
				echo -e "${error_font}创建公私钥失败！"
				exit 1
			fi
			mv ~/.ssh/private_keys.pub ~/.ssh/authorized_keys
			if [[ $? -eq 0 ]];then
				clear
				echo -e "${ok_font}配置公钥成功。"
			else
				clear
				echo -e "${error_font}配置公钥失败！"
				exit 1
			fi
		fi
		chmod 600 /root/.ssh/authorized_keys
		if [[ $? -eq 0 ]];then
				clear
			echo -e "${ok_font}公钥权限设定成功。"
		else
			clear
			echo -e "${error_font}公钥权限设定失败！"
			exit 1
		fi
		chmod 600 /root/.ssh/private_keys
		if [[ $? -eq 0 ]];then
				clear
			echo -e "${ok_font}私钥权限设定成功。"
		else
			clear
			echo -e "${error_font}私钥权限设定失败！"
			exit 1
		fi
		ssh_pubkey_linewords=$(cat /etc/ssh/sshd_config | grep "PubkeyAuthentication ")
		sed -i "s/${ssh_pubkey_linewords}/PubkeyAuthentication yes/g" "/etc/ssh/sshd_config"
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}开启公钥登陆成功。"
		else
			clear
			echo -e "${error_font}开启公钥登陆失败！"
			exit 1
		fi
		ssh_password_linewords=$(cat /etc/ssh/sshd_config | grep "PasswordAuthentication ")
		sed -i "s/${ssh_password_linewords}/PasswordAuthentication no/g" "/etc/ssh/sshd_config"
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}关闭密码登陆成功。"
		else
			clear
			echo -e "${error_font}关闭密码登陆失败！"
			exit 1
		fi
		clear
		echo -e "${ok_font}公钥登录设定完毕。"
		clear
		echo -e "${ok_font}This is your SSH public key:\n${green_backgroundcolor}$(cat ~/.ssh/authorized_keys)${default_fontcolor}"
		echo -e "\n${ok_font}This is your SSH private key:\n${green_backgroundcolor}$(cat ~/.ssh/private_keys)${default_fontcolor}"
		echo -e "\n${ok_font}Your SSH private key's Password: ${green_backgroundcolor}${ssh_key_password}${default_fontcolor}"
	fi
	echo -e "\n\n${ok_font}请求处理完毕。"
}

function prevent_see_publickey(){
	if [ -f ~/.ssh/authorized_keys ]; then
		clear
		echo -e "${ok_font}This is your SSH public key:\n${green_backgroundcolor}${ssh_publickey}${default_fontcolor}"
	else
		clear
		echo -e "${error_font}您未配置PublicKey，无法查看。"
		exit 1
	fi
}

function prevent_see_privatekey(){
	if [ -f ~/.ssh/private_keys ]; then
		clear
		echo -e "${ok_font}This is your SSH private key:\n${green_backgroundcolor}${ssh_privatekey}${default_fontcolor}"
	else
		clear
		echo -e "${error_font}您未使用本脚本配置PrivateKey，无法查看。"
		exit 1
	fi
}

function prevent_see_privatekey_password(){
	if [ -f ~/.ssh/private_keys_password ]; then
		clear
		echo -e "${ok_font}This is your SSH private key's password:\n${green_backgroundcolor}${private_keys_password}${default_fontcolor}"
	else
		clear
		echo -e "${error_font}您未使用本脚本配置PrivateKey，无法查看。"
		exit 1
	fi
}

function restart_service(){
	clear
	echo -e "正在重启服务中..."
	if [[ $OS = 'centos' ]]; then
		/etc/init.d/sshd restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}SSH 重启成功。"
		else
			clear
			echo -e "${error_font}SSH 重启失败！"
			exit 1
		fi
	else
		/etc/init.d/ssh restart
		if [[ $? -eq 0 ]];then
			clear
			echo -e "${ok_font}SSH 重启成功。"
		else
			clear
			echo -e "${error_font}SSH 重启失败！"
			exit 1
		fi
	fi
}

function generate_port(){
	clear
	let default_ssh_new_listenport=$RANDOM+10000
	if [[ 0 -eq $(lsof -i:"${default_ssh_new_listenport}" | wc -l) ]];then
		clear
		echo -e "${ok_font}端口未被占用。"
	else
		clear
		echo -e "${error_font}端口被占用，正在重新生成端口中..."
		generate_port
	fi
}

function check_port(){
	clear
	echo -e "正在检查端口占用情况..."
	if [[ 0 -eq $(lsof -i:"${ssh_new_listenport}" | wc -l) ]];then
		clear
		echo -e "${ok_font}端口未被占用。"
	else
		clear
		echo -e "${error_font}端口被占用，请切换使用其他端口。"
		exit 1
	fi
}

function open_port(){
	clear
	echo -e "正在设置防火墙中..."
	iptables-save > /etc/iptables.up.rules
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}iptables配置保存成功。"
	else
		clear
		echo -e "${error_font}iptables配置保存失败！"
		exit 1
	fi
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}导出iptables配置成功。"
	else
		clear
		echo -e "${error_font}导出iptables配置失败！"
		exit 1
	fi
	chmod +x /etc/network/if-pre-up.d/iptables
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}iptables文件权限设置成功。"
	else
		clear
		echo -e "${error_font}iptables文件权限设置失败！"
		exit 1
	fi
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssh_new_listenport} -j ACCEPT
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}端口开放成功。"
	else
		clear
		echo -e "${error_font}端口开放失败！"
		exit 1
	fi
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssh_new_listenport} -j ACCEPT
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}端口开放成功。"
	else
		clear
		echo -e "${error_font}端口开放失败！"
		exit 1
	fi
	iptables-save > /etc/iptables.up.rules
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}iptables配置保存成功。"
	else
		clear
		echo -e "${error_font}iptables配置保存失败！"
		exit 1
	fi
}

function close_port(){
	clear
	echo -e "正在设置防火墙中..."
	iptables-save > /etc/iptables.up.rules
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}iptables配置保存成功。"
	else
		clear
		echo -e "${error_font}iptables配置保存失败！"
	fi
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}导出iptables配置成功。"
	else
		clear
		echo -e "${error_font}导出iptables配置失败！"
	fi
	chmod +x /etc/network/if-pre-up.d/iptables
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}iptables文件权限设置成功。"
	else
		clear
		echo -e "${error_font}iptables文件权限设置失败！"
		exit 1
	fi
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${ssh_port} -j ACCEPT
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}端口关闭成功。"
	else
		clear
		echo -e "${error_font}端口关闭失败！"
	fi
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${ssh_port} -j ACCEPT
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}端口关闭成功。"
	else
		clear
		echo -e "${error_font}端口关闭失败！"
	fi
	iptables-save > /etc/iptables.up.rules
	if [[ $? -eq 0 ]];then
		clear
		echo -e "${ok_font}iptables配置保存成功。"
	else
		clear
		echo -e "${error_font}iptables配置保存失败！"
	fi
}

function main(){
	set_fonts_colors
	check_os
	check_install_status
	load_configs
	echo_install_list
}
	main
