#!/bin/sh
BASEDIR=$(dirname $0)
svn_username="user"
svn_password="pass"

declare -A svn_dictionary

############################## ADD MORE DIRECTORIES AND REPOS HERE ################################
svn_dictionary[folder_repo1]="https://svn.company.ee/other/path/to/repo1"
svn_dictionary[folder_repo3]="https://svn.company.ee/other/path/to/repo2"
svn_dictionary[folder_repo2]="https://svn.company.ee/other/path/to/repo3"
############################## ADD MORE DIRECTORIES AND REPOS HERE ################################


for K in "${!svn_dictionary[@]}"; do
        svn_dir=$K
        svn_url=${svn_dictionary[$K]}

        if [ ! -d "$svn_dir" ]; then
                echo "Directory $svn_dir does not exist. Doing checkout $svn_url..."
                echo t | svn co "$svn_url" "$BASEDIR/$svn_dir" --username "$svn_username" --password "$svn_password" --no-auth-cache
                find . -name '*.sh' | xargs chmod a+x
        else
                echo "Directory $svn_dir exists. Comparing revision..."
                latest_rev=$(svn info $svn_url --username $svn_username --password $svn_password --no-auth-cache | grep '^Revision:' | sed -e 's/^Revision: //')
                current_rev=$(svn info $BASEDIR/$svn_dir | grep "Revision" | awk '{print $2}')
                if [[ $current_rev != $latest_rev ]]; then
                        echo "Revisions for $svn_url doesnt match - updating $svn_dir"
                        svn up "$BASEDIR/$svn_dir" --username "$svn_username" --password "$svn_password" --no-auth-cache
                        find . -name '*.sh' | xargs chmod a+x
                fi
        fi
done

exit
