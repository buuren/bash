#!/bin/bash
#----------------------------------------------------------------
#	Shell script for WCM continious development
#	
#	Requirements: 
#		1) Jenkins
#		2) SVN repository
#		3) WCM 10g
#		4) SSH access with public/private key pair between 
#
#	Setup guide:
#
#		1. Jenkins.
#			1) Create a new job.
#			2) Configure Source Code Management (Subverion)
#			3) Poll SCM
#			4) Execute shell: 
#				cd /dir/to/script/
#				./script.sh
#
#		2. SVN
#			1) cd svn/hooks
#			2) rename post_commit.tpl to post-commit
#			3) grant execute to jenkins user
#			4) The hook must contain the following:
#			---------------------------------------------------------------------
#				REPOS="$1"
#				REV="$2"
#				UUID=`svnlook uuid $REPOS`
#
# 				old_revision=`less /home/www/svn.sh | grep -iPo 'REV="\d+"'`
# 				new_revision='REV=''"'"$REV"'"'
# 				sed -i "s/$old_revision/$new_revision/Ig" /home/www/svn.sh
#
# 				/usr/bin/wget \
#					--no-proxy \
#					--header "Content-Type:text/plain;charset=UTF-8" \
#					--post-data "`svnlook changed --revision $REV $REPOS`" \
#					--output-document "-" \
#					--timeout=2 \
#					http://localhost:8080/subversion/${UUID}/notifyCommit?rev=$REV
#			---------------------------------------------------------------------
#
#		3. WCM
#			1) WCM doesn't need much configuration. Make sure wcm user has access
#				to install components
#
#		4. SSH
#			You must setup public/private key pairs between WCM server and Jenkins
#			1) Create a SSH user on WCM, which has write access to components folder
#			2) On jenkins, generate private and public keys.
#			3) Copy public key to WCM authorized keys directory
#			4) You can now perform SSH commands without password
#
#	How it works:
#		1. Developer commits a change to SVN
#		2. Poll SCM triggers a jenkins job
#		3. Script.sh is launched
#		4. Export component changes from SVN
#		5. Verify exported files
#		6. Change build number
#		7. Prepare files for achiviing
#		8. Create zip file
#		9. Transfer zip file to WCM component directory
#		10. Install component
#
#----------------------------------------------------------------

rev="152" #<------ Don't touch this :)!

#The following variables must be changed!
comp_local_location="/home/www/components"

ssh_user="wcm2"

wcm_url="172.28.54.146"
wcm_username="sysadmin"
wcm_password="idc"

svn_url="http://localhost/svn/my_project"
svn_username="vladimir"
svn_password="123"

if ! [ -d "/home/www/components" ]; then
	mkdir "/home/www/components"
fi

shopt -s nocasematch


emailmessage="/home/www/mail.txt"
echo "-------------------------------------------">$emailmessage

function send_email_report {

s
	ax=5

	#mail -s "SVN Reivision: $rev" vladimir.kolesnik@post.ee < $emailmessage

}

if ! [[ -z "$rev" ]]; then
	
	find_component=`/usr/bin/svn log -v -r "$rev" "$svn_url" --username "$svn_username" --password "$svn_password" --no-auth-cache`> /dev/null 2>&1
	comp_name=`echo "$find_component" | sed -n '/components/p' | awk -F '/' '{print $5}' | sort -u`
	
	if ! [[ -z "$comp_name" ]]; then

		for svn_component in "$comp_name"; do

			#-----------------------------------------------------------
			#
			#	Function to export components from latest SVN commit.
			#
			#-----------------------------------------------------------

			component_local_location="$comp_local_location/$svn_component"
			echo "Component: $svn_component">>$emailmessage

			if [ -d "$component_local_location" ]; then
				rm -rf 	"$component_local_location"
			fi

			to_export="$svn_url/WCM/components/$svn_component"
			svn export "$to_export" "$component_local_location" --username "$svn_username" --password "$svn_password" --no-auth-cache > /dev/null 2>&1

			#-----------------------------------------------------------
			#
			#	Function to do basic checks after exporting component
			#	from SVN. If HDA file does not exist, break and continue.
			#
			#-----------------------------------------------------------

			find_hda="$component_local_location/$svn_component.hda"
			if [ -f "$find_hda" ]; then
				hda_name="$component_local_location/$svn_component.hda"
			else
				component_folder_small=`echo $svn_component | tr '[:upper:]' '[:lower:]'`
				hda_name="$component_local_location/$component_folder_small.hda"
			fi

			if [ ! -f "$hda_name" ]; then
				echo "Status: FAIL">>$emailmessage
				echo "Reason: Could not find component hda file.">>$emailmessage
				echo "--------------------------------------------------------"
				error_index=1
				send_email_report
				continue
			fi

			#-----------------------------------------------------------
			#
			#	Function to find, change and verify component build number.
			#	Function is called using $1 parameter ($svn_component)
			#
			#-----------------------------------------------------------

			#find build number in D01
			content=$(wget -O - --no-proxy --http-user="$wcm_username" --http-password="$wcm_password" \
			--user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
			'http://'"$wcm_url"'/idc/idcplg?IdcService=CONFIG_INFO' 2>&1)

			component_build=`echo "$content" | awk '/Sort Enabled Components By Name/,/Disabled Component Details/' | grep -iPo '<td>(.*?)</td>'`
			check_component=`echo "$component_build" | grep "$svn_component"`

			if ! [[ -z "$check_component" ]]; then
				while read -r line; do
					build_number=`echo "$line" | grep "$svn_component" | grep -iPo 'build (\d+)' | grep -Po '(\d+)'`
				done <<< "$check_component"
			else
				echo "Status: FAIL">>$emailmessage
				echo "Reason: Couldn't find component in enabled list.">>$emailmessage
				send_email_report
				error_index=1
				continue
			fi

			#Change build number
			build_number_in_hda=`less $hda_name | grep -iPo 'build \d+' | grep -Po '\d+'`
			if [[ "$build_number_in_hda"  =~ ^[0-9]+$ ]]; then
				let new_build_number=$build_number+1
				sed -i "s/(build $build_number_in_hda)/(build $new_build_number)/Ig" "$hda_name"
			else
				echo "Status: FAIL">>$emailmessage
				echo "Reason: Error changing build number. ">>$emailmessage
				send_email_report
				error_index=1
				continue
			fi

			#Verify change results
			current_build_number=`less $hda_name | grep -iPo 'build \d+' | grep -Po '\d+'`
			let build_number_difference=$current_build_number-$build_number

			if [[ $build_number_difference -eq "1" ]]; then
				:
			else
				echo "Status: FAIL"
				echo "Reason: HDA: failed to change build number">>$emailmessage
				send_email_report
				error_index=1
				continue
			fi
	
			#-----------------------------------------------------------
			#
			#	Function which creates a ZIP file ready for installing.
			#
			#-----------------------------------------------------------

			svn_component=$(basename "$component_local_location")
			hda_name_basename=$(basename "$hda_name")
			manifest_time=`date +"%Y-%m-%d %H:%M"`

			if [ -d "$component_local_location/to_zip" ]; then
				rm -rf "$component_local_location/to_zip"
			fi

			mkdir -p "$component_local_location/to_zip/component/$svn_component"

			#Copy lines from existing manifest.hda
			if [ -f "$component_local_location/manifest.hda" ]; then
				sed -n '/<?hda version/,/@Properties LocalData/{/@Properties LocalData/!p}' "$component_local_location/manifest.hda" >> "$component_local_location/to_zip/manifest.hda"
				echo "@Properties LocalData" >> "$component_local_location/to_zip/manifest.hda"
				echo "CreateDate=$manifest_time" >> "$component_local_location/to_zip/manifest.hda"
				echo "blFieldTypes=CreateDate date" >> "$component_local_location/to_zip/manifest.hda"
				echo "ComponentName=$svn_component" >> "$component_local_location/to_zip/manifest.hda"
				echo "blDateFormat=yyyy-MM-dd {H:mm[:ss][zzz]}!tAmerica/Los_Angeles" >> "$component_local_location/to_zip/manifest.hda"
				echo "@end" >> "$component_local_location/to_zip/manifest.hda"
				echo "@ResultSet Manifest" >> "$component_local_location/to_zip/manifest.hda"
				echo "2" >> "$component_local_location/to_zip/manifest.hda"
			else
				echo "Status: FAIL"
				echo "Reason: Manifest fail does not exist.">>$emailmessage
				send_email_report
				error_index=1
				continue
			fi

			echo "entryType" >> "$component_local_location/to_zip/manifest.hda"
			echo "location" >> "$component_local_location/to_zip/manifest.hda"
			
			#Component HDA file.
			if [ -f "$hda_name" ]; then
				cp "$hda_name"  "$component_local_location/to_zip/component/$svn_component/"
				echo "component" >> "$component_local_location/to_zip/manifest.hda"
				echo "$svn_component/$hda_name_basename" >> "$component_local_location/to_zip/manifest.hda"
			fi

			#Readme.txt
			if [ -f "$component_local_location/readme.txt" ]; then
				cp "$component_local_location/readme.txt" "$component_local_location/to_zip/component/$svn_component/"
				echo "componentExtra" >> "$component_local_location/to_zip/manifest.hda"
				echo "$svn_component/readme.txt" >> "$component_local_location/to_zip/manifest.hda"
			fi
			

			#Copy resource folder. Does not need to be include in manifest.
			if [ -d "$component_local_location/resources" ]; then
				cp -r "$component_local_location/resources" "$component_local_location/to_zip/component/$svn_component/"
			fi

			#Copy lib folder.
			if [ -d "$component_local_location/lib" ]; then
				cp -r "$component_local_location/lib" "$component_local_location/to_zip/component/$svn_component/"
				echo "componentLib" >> "$component_local_location/to_zip/manifest.hda"
				echo "$svn_component/lib/">> "$component_local_location/to_zip/manifest.hda"
			fi

			#Copy classes folder.
			if [ -d "$component_local_location/classes" ]; then
				cp -r "$component_local_location/classes" "$component_local_location/to_zip/component/$svn_component/"
				echo "componentClasses" >> "$component_local_location/to_zip/manifest.hda"
				echo "$svn_component/classes/">> "$component_local_location/to_zip/manifest.hda"
			fi
				
			#Template folder. Does not need to be include in manifest.
			if [ -d "$component_local_location/templates" ]; then
				cp -r "$component_local_location/templates" "$component_local_location/to_zip/component/$svn_component/"
			fi


			#environment.cfg
			for full_file_name in "$component_local_location/"*; do
				each_file=$(basename "$full_file_name")

				if [[ "$each_file" == *environment* ]]; then
					cp "$component_local_location/$each_file" "$component_local_location/to_zip/component/$svn_component/"
				fi

			done

			#Publish folder
			if [ -d "$component_local_location/publish" ]; then
				cp -r "$component_local_location/publish" "$component_local_location/to_zip/component/$svn_component/"
				echo "componentExtra" >> "$component_local_location/to_zip/manifest.hda"
				echo "$svn_component/publish/">> "$component_local_location/to_zip/manifest.hda"
			fi

			#Readme.txt
			if [ -f "$component_local_location/config.prop" ]; then
				cp "$component_local_location/config.prop" "$component_local_location/to_zip/component/$svn_component/"
				echo "componentExtra" >> "$component_local_location/to_zip/manifest.hda"
				echo "$svn_component/config.prop" >> "$component_local_location/to_zip/manifest.hda"
			fi

			echo "@end" >> "$component_local_location/to_zip/manifest.hda"
			echo "" >> "$component_local_location/to_zip/manifest.hda"

			cd "$component_local_location/to_zip"
			nano_time=`date +"%Y%m%d%H%M%S%N"`

			#zip_folder=`echo "$svn_component""_backup_"$nano_time".zip"`
			zip_folder=`echo "manifest.zip"`
			zip -r $zip_folder . > /dev/null 2>&1
			zip_folder_location="$component_local_location/to_zip/$zip_folder"

			pscp_command=$(echo Y | pscp -P 522 -l wcm -pw wcm -v "$zip_folder_location" "$wcm_url": 2>&1)
			pscp_output=`echo "$pscp_command"`

			if [[ "$pscp_output" = *Connected* ]]; then

				function for_windows_only {

					#-----------------------------------------------------------
					#
					#	Function to transfer zip file over PSCP. For Windows.
					#
					#-----------------------------------------------------------

					ssh_command='cmd /c copy C:\Users\wcm\Desktop\temp\manifest.zip  F:\wcm\custom\'"$svn_component"'\'
					ssh_command_output=$(ssh "$ssh_user"@"$wcm_url" -p 522 $ssh_command 2>&1)

					if [[ "$ssh_command_output" == *"1 file(s) copied"* ]]; then
						:
					else
						echo "Status: FAIL">>$emailmessage
						echo "Reason: Was unable to transfer file.">>$emailmessage
						echo "$ssh_command_output">>$emailmessage
						send_email_report
						error_index=1
						continue
					fi

				}
				for_windows_only

				#install component:
				install_command_output=$(wget -O - --no-proxy --spider --http-user="$wcm_username" --http-password="$wcm_password" \
					--user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
					'http://'"$wcm_url"'/idc/idcplg?IdcService=UPLOAD_NEW_COMPONENT&ComponentName='"$svn_component"'&IDC_Id=idc&location='"$svn_component"'/' 2>&1)

				if [[ "$install_command_output" = *"Connecting to $wcm_url:80... connected."* ]]; then
					:
				else
					echo "Status: FAIL">>$emailmessage
					echo "Reason: Installation failed.">>$emailmessage
					echo "$install_command_output">>$emailmessage
					send_email_report
					error_index=1
					continue
				fi
		
			else
				echo "Status: FAIL">>$emailmessage
				echo "Reason: $pscp_output">>$emailmessage
				send_email_report
				error_index=1
				continue
			fi

			echo "Status: Success">>$emailmessage
			error_index=0
			send_email_report
			
			rm -rf "$component_local_location"

		done
	else
		echo "No changes to componenets in that revision. Nothing to export.">>$emailmessage
		send_email_report
	fi
else 
	echo "Missing argument: revision. Nothing to export.">>$emailmessage
	send_email_report
fi
echo "-------------------------------------------">>$emailmessage

cat "$emailmessage" #or send it with send_email_report

if [[ "$error_index" == "1" ]]; then
	exit 1
else 
	exit 0
fi

shopt -u nocasematch
