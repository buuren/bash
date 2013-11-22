Personal customized bash prompt. Paste it to your $HOME/.bashrc file:

OUTPUT=$(hostname -I)
ipadd=`echo $OUTPUT`
export PS1='\[\033[0;36m\][\t]\[\033[0;36m\]\[\033[0;31m\]\[\033[0;36m\]\[\033[0;36m\][\[\033[0;32m\]\u\[\033[0;36m\]@\[\033[0;31m\]\h_$ipadd:\[\033[0;36m\]\w\[\033[0;36m\]]\n\[\033[0;32m\]\$ \[\033[0m\]'


The bash prompt will look like:
[hosttime][username@hostname_ipaddress:~currentdirectorypath]

Example:

[10:12:57][oracle@oracle7_172.28.54.169:~]
$ (commands will go new line)

[10:17:54][oracle@oracle7_172.28.54.169:/oracle/ucm/server]
$ cd /home/oracle
