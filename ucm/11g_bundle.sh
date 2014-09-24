#!/bin/bash
# Export all components from SVN repo -> create zip file which contains all components -> deploy to UCM server
current_time=`date +"%T"`

function check_function_status () {

	if [[ ! -z "$1" ]]; then
		echo "[$current_time] >>>Error in function: $2" >> "$log_file"
		echo "[$current_time] >>>Error(s):" >> "$log_file"
		echo -e "[$current_time] $1" >> "$log_file"
		exit 1
	else
		echo "[$current_time] >>>Function OK: $2" >> "$log_file"
	fi

}

# Main location of all files. Must have RWX in here.
main_dir="/home/www"

# Contains location of exported components.
# Folder is created when we export components using $svn_export
comp_local_location="$main_dir/components/EDMS" 

# Directory to store zip files prepared to commit. 
# Temporary folder to hold manifest.zip's for 1 single bundle.zip
bundle_location="$main_dir/bundle"

# Directory to commit last zip file.
# Directory is created when we do checkout from SVN. We checkout folder "builds" so builds is created automatically. 
commit_folder="$main_dir/builds" 

nano_time=`date +"%Y-%m-%d_%H-%M-%S"`
# All reports are placed into this logfile:
log_file="$main_dir/log_`date +"%m-%d-%y"`.txt"

echo "[$current_time] ----------------------------------------------------------------------------------------------" >> "$log_file"
echo "[$current_time] Starting script..." >> "$log_file"
echo "[$current_time] Checking permissions..." >> "$log_file"

function check_permissions {

	users[0]="vladimir" #Leave blank to user current user. 

	# array to hold directories where we check permissions in
	item[0]="$main_dir"

	# array to hold which permissions we check
	rights[0]="r"
	rights[1]="w"
	rights[2]="x"

	results=() #empty array

	# Function to check permissions. This is necessary to do because we do a lot of read/write/delete actions.
	# Will go through all directories in [item] array and for each of them check permissions in [rights] array.

	if [[ ${users[@]} == "" ]]; then
		users[0]=`awk -v val="$UID" -F ":" '$3==val{print $1}' /etc/passwd` #use current user
	fi

	for each_user in "${users[@]}"; do
		user_groups=`groups $each_user | sed -e 's/^\w*\ *: //'` #trim "user : "

		for each_item in "${item[@]}"; do

			if [ -d "$each_item" ] || [ -f "$each_item" ]; then

				for each_right in "${rights[@]}"; do
					
					each_item_permissions=`ls -la $each_item`
					each_item_rwx=`stat -c %A $each_item`
					each_item_owner=`stat -c '%U' $each_item`
					each_item_group=`stat -c '%G' $each_item`

					owner_rights=`echo $each_item_rwx | cut -c2-4`
					group_rights=`echo $each_item_rwx | cut -c5-7`
					all_rights=`echo $each_item_rwx | cut -c8-10`

					# Check all(other) permissions
					if [[ "$all_rights" == *"$each_right"* ]]; then
						:
					else
						# Check group permissions
						if [[ "$group_rights" == *"$each_right"* && "$user_groups" == *"$each_item_group"* ]]; then
							:
						else 
							# Check owner(user) permissions
							if [[ "$owner_rights" == *"$each_right"* && "$user_name" == *"$each_item_owner"* ]]; then
								:
							else
								results+=("User: $each_user\nFolder: $each_item\nRight: $each_right\nResults: FAIL\n--------------")
							fi
						fi
					fi

				done

			else
				results+=("User: $each_user\nFolder: $each_item\nResults: FAIL - Not found.\n--------------")
			fi

		done

	done

	# Go through results array. If results contains any FAIL, 
	for each_result in "${results[@]}"; do
		if [[ "$each_result" == *FAIL* ]]; then
			echo -e "Fix missing access right:\n$each_result"
			exit 1
		fi
	done

}
# What is that -> In order to determine whether function succeeded, we store function output into variable.
# After that, there is another function "check_permissions" to check if output is empty or not. When function
# succeeded, output is empty (no errors), if something went wrong -> it will contain an error. If it contains an
# error -> break script. 
check_permissions_output=$(check_permissions 2>&1)
check_function_status "$check_permissions_output" "check_permissions"

echo "[$current_time] Permissions OK." >> "$log_file"

#---------------------------------------------------------
# WCM SETTINGS
# Change accordingly
wcm_url="192.168.1.0"
wcm_username="weblogic"
wcm_password="Weblogic1"
#---------------------------------------------------------
# SVN SETTINGS
# Change accordingly
svn_username="weblogic"
svn_password="weblogic1"
svn_url="https://svn.repo.com/path_to_builds/builds"
svn_export_url="https://svn.repo.com/path_to_comps/components"
#---------------------------------------------------------

function prepare_folders {

	# Remove all existing dirs

	if [ -d "$commit_folder" ]; then
		rm -rf "$commit_folder"
	fi

	if [ -d "$comp_local_location" ]; then
		rm -rf "$comp_local_location"
	fi

	if [ -d "$bundle_location" ]; then
		rm -rf "$bundle_location"
	fi

	mkdir -p "$bundle_location/components/custom/"

}
prepare_folders_output=$(prepare_folders 2>&1)
check_function_status "$prepare_folders_output" "prepare_folders"


function generate_manifest_hda {

	# Create manifest.hda file and fill with basic info.

	echo '<?hda version="11.1.1.8.0-2013-07-11 17:07:21Z-r106802" jcharset="UTF8" encoding="utf-8"?>' > "$bundle_location/manifest.hda"
	echo '@Properties LocalData' >> "$bundle_location/manifest.hda"
	echo 'IDC_Name=earchive_dev' >> "$bundle_location/manifest.hda"
	echo "TaskName=$nano_time" >> "$bundle_location/manifest.hda"
	echo "TaskSession=`echo "scale=18; $RANDOM/32767" | bc | sed "s/.//"`" >> "$bundle_location/manifest.hda"
	echo 'blDateFormat=M/d{/yy}{ h:mm[:ss]{ a}}!mAM,PM!tEurope/Stockholm' >> "$bundle_location/manifest.hda"
	echo 'blFieldTypes=exportDate date' >> "$bundle_location/manifest.hda"
	echo 'cmuTaskVersion=2' >> "$bundle_location/manifest.hda"
	#echo 'customActionName=export_earchive_menu' >> "$bundle_location/manifest.hda"
	echo 'exportComponentVersion=2013_04_16-dev (rev 104234)' >> "$bundle_location/manifest.hda"
	echo 'exportDate=12/4/13 2:54 PM' >> "$bundle_location/manifest.hda"
	echo 'exportHost=lx61158.sbcore.net' >> "$bundle_location/manifest.hda"
	echo 'exportOriginalTask=bundle' >> "$bundle_location/manifest.hda"
	echo 'exportServerVersion=7.3.5.185' >> "$bundle_location/manifest.hda"
	echo '@end' >> "$bundle_location/manifest.hda"

}
generate_manifest_hda_output=$(generate_manifest_hda 2>&1)
check_function_status "$generate_manifest_hda_output" "generate_manifest_hda"

function header_for_componenthda {

	# Create components.hda file.

	echo '<?hda version="11.1.1.8.0-2013-07-11 17:07:21Z-r106802" jcharset="UTF8" encoding="utf-8"?>' > "$bundle_location/components.hda"
	echo '@Properties LocalData' >> "$bundle_location/components.hda"
	echo 'blDateFormat=M/d{/yy}{ h:mm[:ss]{ a}}!mAM,PM!tEurope/Stockholm' >> "$bundle_location/components.hda"
	echo '@end' >> "$bundle_location/components.hda"
	echo '@ResultSet SectionItems' >> "$bundle_location/components.hda"
	echo '3' >> "$bundle_location/components.hda"
	echo 'name' >> "$bundle_location/components.hda"
	echo 'type' >> "$bundle_location/components.hda"
	echo 'value' >> "$bundle_location/components.hda"

}
header_for_componenthda_output=$(header_for_componenthda 2>&1)
check_function_status "$header_for_componenthda_output" "header_for_componenthda"

function checkout_and_export {

	# Small function which checkouts and exports components from SVN using variables: $svn_url and $svn_export_url

	cd "$main_dir"
	# Checkout existing builds
	echo "[$current_time] Checkout builds from SVN to $commit_folder" >> "$log_file"
	echo t | svn co "$svn_url" --username "$svn_username" --password "$svn_password" --no-auth-cache >> "$log_file"

	# Export all components
	echo "[$current_time] Exporting all components from SVN to $comp_local_location" >> "$log_file"
	echo t | svn export "$svn_export_url" "$comp_local_location" --username "$svn_username" --password "$svn_password" --no-auth-cache >> "$log_file"

}
checkout_and_export

# Hack
shopt -s nocasematch

function remove_comps {

	# Manually remove unnecessary componenets.
	# We don't want to install every single component from SVN repo, so remove some of they are exported.
	rm -rf $comp_local_location/COMP_NAME

}
remove_comps_output=$(remove_comps 2>&1)
check_function_status "$remove_comps_output" "remove_comps"
 
function header_for_taskshda {

	# Create task.hda.

	echo '<?hda version="11.1.1.8.0-2013-07-11 17:07:21Z-r106802 jcharset="UTF8" encoding="utf-8"?>' > "$bundle_location/task.hda"
	echo '@Properties LocalData' >> "$bundle_location/task.hda"
	echo "TaskName=$nano_time" >> "$bundle_location/task.hda"
	echo 'blDateFormat=M/d{/yy}{ h:mm[:ss]{ a}}!mAM,PM!tEurope/Stockholm' >> "$bundle_location/task.hda"
	echo 'cmuTaskVersion=2' >> "$bundle_location/task.hda"
	echo "origTaskName=$nano_time" >> "$bundle_location/task.hda"
	echo '@end' >> "$bundle_location/task.hda"
	echo "@ResultSet TaskSections" >> "$bundle_location/task.hda"
	echo "1" >> "$bundle_location/task.hda"
	echo "SectionID" >> "$bundle_location/task.hda"
	echo "components" >> "$bundle_location/task.hda"
	echo "@end" >> "$bundle_location/task.hda"
	echo "@ResultSet components" >> "$bundle_location/task.hda"
	echo "1" >> "$bundle_location/task.hda"
	echo "item" >> "$bundle_location/task.hda"

	for svn_component in $comp_local_location/*; do

		svn_component=$(basename "$svn_component")
		component_local_location="$comp_local_location/$svn_component"

		if [[ -d $component_local_location ]]; then
			echo "$svn_component" >> "$bundle_location/task.hda"
		fi

	done

	echo "@end" >> "$bundle_location/task.hda"
	echo '@ResultSet display-components' >> "$bundle_location/task.hda"
	echo '18' >> "$bundle_location/task.hda"
	echo 'name' >> "$bundle_location/task.hda"
	echo 'location' >> "$bundle_location/task.hda"
	echo 'status' >> "$bundle_location/task.hda"
	echo 'classpath' >> "$bundle_location/task.hda"
	echo 'libpath' >> "$bundle_location/task.hda"
	echo 'installID' >> "$bundle_location/task.hda"
	echo 'featureExtensions' >> "$bundle_location/task.hda"
	echo 'classpathorder' >> "$bundle_location/task.hda"
	echo 'libpathorder' >> "$bundle_location/task.hda"
	echo 'Launchers' >> "$bundle_location/task.hda"
	echo 'LaunchersOrder' >> "$bundle_location/task.hda"
	echo 'componentsToDisable' >> "$bundle_location/task.hda"
	echo 'componentTags' >> "$bundle_location/task.hda"
	echo 'componentType' >> "$bundle_location/task.hda"
	echo 'useType' >> "$bundle_location/task.hda"
	echo 'version' >> "$bundle_location/task.hda"
	echo 'hasPreferenceData' >> "$bundle_location/task.hda"
	echo 'item' >> "$bundle_location/task.hda"

}
header_for_taskshda_output=$(header_for_taskshda 2>&1)
check_function_status "$header_for_taskshda_output" "header_for_taskshda"

function prepare_zip {

	# Main function.
	# Will prepare structure of Oracle UCM 11g components.

	for svn_component in $comp_local_location/*; do

		svn_component=$(basename "$svn_component")
		component_local_location="$comp_local_location/$svn_component"

		if [[ -d $component_local_location ]]; then

			echo "[$current_time] Processing component $svn_component." >> "$log_file"
			find_hda="$component_local_location/$svn_component.hda"

			if [ -f "$find_hda" ]; then
				hda_name="$component_local_location/$svn_component.hda"
			else
				component_folder_small=`echo $svn_component | tr '[:upper:]' '[:lower:]'`
				hda_name="$component_local_location/$component_folder_small.hda"
			fi

			if [ ! -f "$hda_name" ]; then
				echo "[$current_time] Status: FAIL" >> "$log_file"
				echo "[$current_time] Reason: Could not find component $find_hda file." >> "$log_file"
				echo "[$current_time] --------------------------------------------------------" >> "$log_file"
				continue
			else
				echo "[$current_time] HDA: $hda_name" >> "$log_file"
			fi

			function change_build_number {

				echo "[$current_time] Starting to change build number." >> "$log_file"
				content=$(wget -O - --no-proxy --http-user="$wcm_username" --http-password="$wcm_password" \
				--user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
				'http://production.ucm11g:port/_dav/cs/idcplg?IdcService=CONFIG_INFO&IsSoap=1' 2>&1)

				comp_name=`echo "$content" | awk '/"EnabledComponents"/,/UserAttribInfo/' | grep '<idc:field name="name">' | grep -oP '(?<=\>).*(?=\<)'`

				if [[ "$comp_name" == *"$svn_component"* ]]; then
					build_number=`echo "$content" | awk '/'"$svn_component"'/,/row/' | grep build | grep -oP "(?<=\().*(?=\))" | grep -oP "(\d+)"`
					echo "[$current_time] Component is enabled. Build number is $build_number" >> "$log_file"
				else
					echo "[$current_time] Status: FAIL" >> "$log_file"
					echo "[$current_time] Reason: Couldn't find component in enabled list." >> "$log_file"
					continue
				fi

				#Change build number
				build_number_in_hda=`less $hda_name | grep -iPo 'build \d+' | grep -Po '\d+'`
				if [[ "$build_number_in_hda" =~ ^[0-9]+$ ]]; then
					let new_build_number=$build_number+1
					sed -i "s/(build $build_number_in_hda)/(build $new_build_number)/Ig" "$hda_name"
					echo "[$current_time] Changing build number: $build_number > $new_build_number" >> "$log_file"
				else
					echo "[$current_time] Status: FAIL" >> "$log_file"
					echo "[$current_time] Reason: Error changing build number. " >> "$log_file"
				fi

				#Verify change results
				echo "[$current_time] Verifying change build number results" >> "$log_file"

				current_build_number=`less $hda_name | grep -iPo 'build \d+' | grep -Po '\d+'`
				let build_number_difference=$current_build_number-$build_number

				if [[ $build_number_difference -eq "1" ]]; then
					echo "[$current_time] Change was succesfull." >> "$log_file"
				else
					echo "[$current_time] Status: FAIL" >> "$log_file"
					echo "[$current_time] Reason: Failed to change build number" >> "$log_file"
					continue
				fi
			}
			#change_build_number_output=$(change_build_number 2>&1)
			#check_function_status "$change_build_number_output" "change_build_number"

			svn_component=$(basename "$component_local_location")
			hda_name_basename=$(basename "$hda_name")
			manifest_time=`date +"%d-%m-%y %H:%M PM"`

			if [ -d "$component_local_location/to_zip" ]; then
				rm -rf "$component_local_location/to_zip"
			fi

			mkdir -p "$component_local_location/to_zip/component/$svn_component"

			function prepare_manifest_for_zip {

				echo "[$current_time] Preparing manifest.zip." >> "$log_file"

				#Copy lines from existing manifest.hda
				if [ -f "$component_local_location/manifest.hda" ]; then
					#echo "replacing $component_local_location/manifest.hda"
					sed -i "s/@Properties LocalData/@Properties LocalData\nComponentName=${svn_component}\nCreateDate=${manifest_time}/" "$component_local_location/manifest.hda"
					sed -i '0,/@end/s//blFieldTypes=CreateDate date\n@end/' "$component_local_location/manifest.hda"
					cp "$component_local_location/manifest.hda" "$component_local_location/to_zip/manifest.hda"
				else
					echo "[$current_time] Status: FAIL" >> "$log_file"
					echo "[$current_time] Reason: Manifest fail does not exist." >> "$log_file"
					continue
				fi
				
				#Component HDA file.
				if [ -f "$hda_name" ]; then
					cp "$hda_name" "$component_local_location/to_zip/component/$svn_component/"
				fi

				#Readme.txt
				if [ -f "$component_local_location/readme.txt" ]; then
					cp "$component_local_location/readme.txt" "$component_local_location/to_zip/component/$svn_component/"
				fi

				#Copy resource folder. Does not need to be include in manifest.
				if [ -d "$component_local_location/resources" ]; then
					cp -r "$component_local_location/resources" "$component_local_location/to_zip/component/$svn_component/"
				fi

				#Copy lib folder.
				if [ -d "$component_local_location/lib" ]; then
					cp -r "$component_local_location/lib" "$component_local_location/to_zip/component/$svn_component/"
				fi

				#Copy classes folder.
				if [ -d "$component_local_location/classes" ]; then
					cp -r "$component_local_location/classes" "$component_local_location/to_zip/component/$svn_component/"
				fi

				#Publish folder
				if [ -d "$component_local_location/publish" ]; then
					cp -r "$component_local_location/publish" "$component_local_location/to_zip/component/$svn_component/"
				fi

				#config
				if [ -f "$component_local_location/config.prop" ]; then
					cp "$component_local_location/config.prop" "$component_local_location/to_zip/component/$svn_component/"
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

			}
			prepare_manifest_for_zip_output=$(prepare_manifest_for_zip 2>&1)
			check_function_status "$prepare_manifest_for_zip_output" "prepare_manifest_for_zip"

			cd "$component_local_location/to_zip"
			echo "[$current_time] Zipping archive...." >> "$log_file"

			zip_folder=`echo "manifest.zip"`
			zip -r $zip_folder . > /dev/null 2>&1
			zip_folder_location="$component_local_location/to_zip/$zip_folder"

			mkdir "$bundle_location/components/custom/$svn_component"
			cp "$zip_folder_location" "$bundle_location/components/custom/$svn_component/"
			#---------------------------------------------------------------------------------------
			#Task.hda
			function generate_task_hda {
			
				echo "$svn_component" >> "$bundle_location/task.hda"
				echo "custom/$svn_component/$svn_component.hda" >> "$bundle_location/task.hda"
				echo "Enabled" >> "$bundle_location/task.hda"
				if [ -d "$component_local_location/classes" ]; then
					echo ""'$COMPONENT_DIR'"/classes" >> "$bundle_location/task.hda"
				else
					echo "" >> "$bundle_location/task.hda"
				fi

				if [ -d "$component_local_location/lib" ]; then
					echo ""'$COMPONENT_DIR/lib'"" >> "$bundle_location/task.hda"
				else
					echo "" >> "$bundle_location/task.hda"
				fi
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "" >> "$bundle_location/task.hda"
				echo "local" >> "$bundle_location/task.hda"
				echo "local" >> "$bundle_location/task.hda"
				echo "2013_11_27(build 1)" >> "$bundle_location/task.hda"
				echo `cat $hda_name | grep -oP '(?<=hasPreferenceData=).*'` >> "$bundle_location/task.hda"
				echo "$svn_component" >> "$bundle_location/task.hda"

			}
			generate_task_hda_output=$(generate_task_hda 2>&1)
			check_function_status "$generate_task_hda_output" "generate_task_hda"

			echo "[$current_time] task.hda done" >> "$log_file"
			#Componenets.hda
			function generate_components_hda {

				echo "components_inst_$svn_component" >> "$bundle_location/components.hda"
				echo "3" >> "$bundle_location/components.hda"
				echo "components_inst_$svn_component.hda" >> "$bundle_location/components.hda"
				echo "components_config_$svn_component" >> "$bundle_location/components.hda"
				echo "3" >> "$bundle_location/components.hda"
				echo "components_config_$svn_component.hda" >> "$bundle_location/components.hda"
				echo "components_$svn_component" >> "$bundle_location/components.hda"
				echo "0" >> "$bundle_location/components.hda"
				echo "custom/$svn_component/manifest.zip" >> "$bundle_location/components.hda"

				head -2 "$component_local_location/to_zip/manifest.hda" > "$bundle_location/components/components_inst_$svn_component.hda"
				echo "blDateFormat=M/d{/yy}{ h:mm[:ss]{ a}}!mAM,PM!tEurope/Stockholm" >> "$bundle_location/components/components_inst_$svn_component.hda"
				echo "@end" >> "$bundle_location/components/components_inst_$svn_component.hda"

				head -2 "$component_local_location/to_zip/manifest.hda" > "$bundle_location/components/components_config_$svn_component.hda"
				echo "blDateFormat=M/d{/yy}{ h:mm[:ss]{ a}}!mAM,PM!tEurope/Stockholm" >> "$bundle_location/components/components_config_$svn_component.hda"
				echo "@end" >> "$bundle_location/components/components_config_$svn_component.hda"

			}
			generate_components_hda_output=$(generate_components_hda 2>&1)
			check_function_status "$generate_components_hda_output" "generate_components_hda"
			echo "[$current_time] components.hda done" >> "$log_file"
		else
			echo "[$current_time] $component_local_location is not a directory." >> "$log_file"
			#exit 1
		fi 

	done

}
prepare_zip_output=$(prepare_zip 2>&1)
check_function_status "$prepare_zip" "prepare_zip"
# Put @end tag at the end of task.hda and components.hda
echo "@end" >> "$bundle_location/task.hda"
echo "@end" >> "$bundle_location/components.hda"

function zip_files {

	echo "[$current_time] Preparing bundle for zipping..." >> "$log_file"
	cd "$bundle_location"
	zip_bundle=`echo "bundle.zip"`
	zip -r $zip_bundle . > /dev/null
	zip_bundle_location="$bundle_location/$zip_bundle"

	echo "[$current_time] Bundle is done: $zip_bundle_location" >> "$log_file"
	echo "[$current_time] Moving $zip_bundle_location to $commit_folder/$nano_time.zip" >> "$log_file"
	mv "$zip_bundle_location" "$commit_folder/$nano_time.zip"

	cd "$commit_folder"
	echo "[$current_time] Commiting $commit_folder/$nano_time.zip to SVN..." >> "$log_file"
	echo t | svn add "$commit_folder/$nano_time.zip" >> "$log_file"
	echo t | svn commit -m "Adding ZIP file back to SVN builds" --username "$svn_username" --password "$svn_password" --no-auth-cache >> "$log_file"
	echo "[$current_time] Commit done." >> "$log_file"

}
zip_files_output=$(zip_files 2>&1)
check_function_status "$zip_files_output" "zip_files"

function upload_components {

	echo "Uploading $commit_folder/$nano_time.zip...." >> "$log_file"

	upload_output=$(curl --noproxy "$wcm_url" -u "$wcm_username":"$wcm_password" -F "IdcService=CMU_UPLOAD_BUNDLE" -F "IsSoap=1" \
		-F "bundleName=@$commit_folder/$nano_time.zip" -F "createExportTemplate=" -F "forceBundleOverwrite=yes" "$wcm_url:16200/_dav/cs/idcplg" 2>&1)

	content=$(wget -O - --no-proxy --http-user="$wcm_username" --http-password="$wcm_password" \
		--user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
		"http://$wcm_url:16200/_dav/cs/idcplg?IdcService=CMU_GET_ALL_IMPORT_BUNDLES" 2>&1)

	find_bundle=`echo "$content" | grep "$nano_time"`

	if [[ "$find_bundle" ]]; then

		echo "[$current_time] Upload success" >> "$log_file"

	else
		echo "[$current_time] Upload failed:" >> "$log_file"
		echo "[$current_time] $upload_output" >> "$log_file"
		exit 1
	fi

}

function import_components {

	#Components have been installed.

	echo "[$current_time] Starting to import..." >> "$log_file"

	import_output=$(curl --noproxy "$wcm_url" -u "$wcm_username":"$wcm_password" -F "IdcService=CMU_UPDATE_AND_CREATE_ACTION" -F "IsSoap=1" \
	-F "isContinueOnError=" -F "isOverwrite=1" -F "sectionItemList=" -F "TaskName=$nano_time" -F "isImport=1" "$wcm_url:16200/_dav/cs/idcplg")
	#We need to give some time for content server to import zip file, let's sleep a bit:
	echo "[$current_time] Sleeping for 10 seconds...." >> "$log_file"
	sleep 10

}

function enable_components {

	echo "[$current_time] Starting to enable components..." >> "$log_file"

	for svn_component in $comp_local_location/*; do
		
		svn_component=$(basename "$svn_component")
		component_local_location="$comp_local_location/$svn_component"

		echo "[$current_time] Checking $svn_component..." >> "$log_file"

		if [[ -d $component_local_location ]]; then

			content=$(wget -O - --no-proxy --http-user="$wcm_username" --http-password="$wcm_password" \
			--user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
			"http://$wcm_url:16200/_dav/cs/idcplg?IdcService=CONFIG_INFO&IsSoap=1" 2>&1)

			comp_name=`echo "$content" | awk '/DisabledComponents/,/UserAttribInfo/' | grep '<idc:field name="name">' | grep -oP '(?<=\>).*(?=\<)'`

			if [[ "$comp_name" == *"$svn_component"* ]]; then

				awk_var="/$svn_component/,/hasPreferenceData/"
				comp_status=`echo "$content" | awk "$awk_var" | grep '<idc:field name="status">' | grep -oP '(?<=\>).*(?=\<)'`

				if [[ "$comp_status" == "Enabled" ]]; then
					echo "[$current_time] $svn_component is Enabled. Do nothing." >> "$log_file"
				elif [[ "$comp_status" == "Disabled" ]]; then
					echo "[$current_time] $svn_component is Disabled. Starting Enable process..." >> "$log_file"

					enable_output=$(curl --noproxy "$wcm_url" -u "$wcm_username":"$wcm_password" -F "IdcService=ADMIN_TOGGLE_COMPONENTS" -F "IsSoap=1" \
					-F "isEnable=1" -F "IDC_Id=UCM_server1" -F "ComponentNames=$svn_component" "$wcm_url:16200/_dav/cs/idcplg" 2>&1)
					#echo "$enable_output" >> "$log_file"
					echo "[$current_time] Done" >> "$log_file"

				else
					echo "[$current_time] Unknown status: $comp_status. Error" >> "$log_file"
				fi

			else 
				echo "[$current_time] Component doens't exist." >> "$log_file"
			fi

		else
			echo "[$current_time] $svn_component is not a directory" >> "$log_file"
		fi

	done
}

function uninstall_components {

	for svn_component in $comp_local_location/*; do
	
	svn_component=$(basename "$svn_component")
	component_local_location="$comp_local_location/$svn_component"

	if [[ -d $component_local_location ]]; then

		content=$(wget -O - --no-proxy --http-user="$wcm_username" --http-password="$wcm_password" \
		--user-agent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" \
		"http://$wcm_url:16200/_dav/cs/idcplg?IdcService=CONFIG_INFO&IsSoap=1" 2>&1)

		comp_name=`echo "$content" | grep '<idc:field name="name">' | grep -oP '(?<=\>).*(?=\<)'`

		if [[ "$comp_name" == *"$svn_component"* ]]; then

			echo "[$current_time] $svn_component exists. Starting to uninstall..." >> "$log_file"

			echo "[$current_time] Disabling $svn_component..." >> "$log_file"
			disable_output=$(curl --noproxy "$wcm_url" -u "$wcm_username":"$wcm_password" -F "IdcService=ADMIN_TOGGLE_COMPONENTS" \
			-F "IsSoap=1" -F "isEnable=0" -F "IDC_Id=UCM_server1" -F "ComponentNames=$svn_component" \
			-F "EnabledComponentList=$svn_component" "$wcm_url:16200/_dav/cs/idcplg" 2>&1)
			sleep 2

			echo "[$current_time] Uninstalling $svn_component..." >> "$log_file"
			uninstall_output=$(curl --noproxy "$wcm_url" -u "$wcm_username":"$wcm_password" -F "IdcService=UNINSTALL_COMPONENT" -F "IsSoap=1" \
			-F "IDC_Id=$idc_id" -F 'BackUrl=%2Fcs%2Fidcplg%3FIdcService%3DGET_COMPONENT_DATA%26IDC_Id%3DUCM_server1' \
			-F "ComponentName=$svn_component" "$wcm_url:16200/_dav/cs/idcplg" 2>&1)

			uninstall_status=`echo "$uninstall_output" | grep '<idc:field name="StatusMessage">' | grep -oP '(?<=\>).*(?=\<)'`

			if [[ "$uninstall_status" == *"Unable"* ]]; then
				echo "Failed to uninstall $svn_component." >> "$log_file"
				echo "$uninstall_status" >> "$log_file"
				echo "[$current_time] Error" >> "$log_file"
			else 
				echo "Succesfully uninstalled $svn_component" >> "$log_file"
				echo "$uninstall_status" >> "$log_file"
				echo "[$current_time] Done" >> "$log_file"
			fi
			sleep 2

		else 
			echo "[$current_time] $svn_component doens't exist. Nothing to uninstall" >> "$log_file"
		fi

	else
		echo "[$current_time] $svn_component is not a directory" >> "$log_file"
	fi

done

}

upload_components
import_components
enable_components
#uninstall_components

