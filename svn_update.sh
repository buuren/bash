#!/bin/sh
BASEDIR=$(dirname $0)
svn_username="uer"
svn_password="pass"

declare -A svn_dictionary

############################## ADD MORE DIRECTORIES AND REPOS HERE ################################
svn_dictionary[dir1]="https://svn.host.com/dir1"
svn_dictionary[dir2]="https://svn.host.com/dir2"
svn_dictionary[dir3]="https://svn.host.com/dir3"
svn_dictionary[dir4]="https://svn.host.com/dir4"
svn_dictionary[dir5]="https://svn.host.com/dir5"

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
                else
                        echo "No need to update $svn_dir"
                fi
        fi
done

exit
