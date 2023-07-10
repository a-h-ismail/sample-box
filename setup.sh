#!/bin/bash
if [ $EUID -ne 0 ]; then
    echo "You must run this as root, try with sudo."
    exit 1
fi

function get_section {
    awk -v "section=[$1]" -f get_configuration.awk auto-setup.conf
}

function exit_on_fail {
    if [ $1 -ne 0 ]; then
        exit 1
    fi
}

system_type=$(get_section System)
add_packages=$(get_section 'Add Packages')
remove_packages=$(get_section 'Remove Packages')
req_flatpacks=$(get_section Flatpak)
system_units=$(get_section 'System Units')
all_users_units=$(get_section 'User Units')
files_mapping=$(get_section Files)
pre_script=$(get_section Pre)
post_script=$(get_section Post)
post_package_install=$(get_section 'Post Packages')

if [ -n "$add_packages" ] && [ -n "$req_flatpacks" ]; then
    echo "Checking network connectivity..."
    ping -c 4 8.8.8.8 &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Connect to the internet and try again."
        exit 2
    fi
fi

# Execute the pre-install script
if [ -n "$pre_script" ]; then
    ./"$pre_script" "$system_type"
fi

# Install/Remove packages depending on your system type
if [ -n "$system_type" ]; then
    # Fedora and derivatives
    if [ "$system_type" == "rpm" ]; then
        dnf install $add_packages -y

        if [ -n "$req_flatpacks" ]; then
            dnf install flatpak
        fi

        dnf remove $remove_packages -y &&\
        dnf upgrade -y
        exit_on_fail $?
    fi
    # Debian/Ubuntu derivatives
    if [ "$system_type" == "deb" ]; then
        apt-get update &&\
        apt-get install $add_packages -y
        exit_on_fail $?

        if [ -n "$req_flatpacks" ]; then
            apt-get install flatpak -y
        fi

        apt-get remove --purge $remove_packages -y &&\
        apt-get autoremove -y &&\
        apt-get upgrade -y
        exit_on_fail $?
    fi
fi

# Install Flatpaks
if [ -n "$req_flatpacks" ]; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install $req_flatpacks -y
fi

# Execute post package install script
if [ -n "$post_package_install" ]; then
    ./"$post_package_install" "$system_type"
fi

# Copy the files to the given locations
if [ -n "$files_mapping" ]; then
    echo "Copying files..."
    # Extract the source/destination pairs
    for i in $(seq 1 $(echo "$files_mapping" | wc -l)); do
        # Get source and destination paths by splitting each line at the ':' delimiter
        # May get confused if the filename has : in it, should mitigate that
        source=$(echo "$files_mapping" | awk -F ':' "NR == $i { printf \"%s\", \$1; exit }")
        destination=$(echo "$files_mapping" | awk -F ':' "NR == $i { printf \"%s\", \$2; exit }")
        # Clear it up from the previous iteration
        unset new_name
        mkdir -p "$destination"
        # Case of source being a directory
        if [ -d "$source" ]; then
            cp -rf "$source"/. "$destination"
            # If an ACL file exists, restore the ACLs to the destination and delete the file
            if [ -e "$source/acls.txt" ]; then
                tmp="$PWD"
                cd "$destination"
                setfacl --restore=acls.txt
                rm acls.txt
                cd "$tmp"
            fi
        # Case of a file as source, the desired ACLs should be in the same directory as the file
        elif [ -f "$source" ]; then
            source_dir=$(dirname "$source")

            # Get the new name as indicated in the config
            new_name=$(echo "$files_mapping" | awk -F ':' "NR == $i { printf \"%s\", \$3; exit }")
            if [ -n "$new_name" ] && [ -d "$destination/$new_name" ]; then
                echo "Error, the requested filename is already taken by a directory: $destination/$new_name"
                continue
            fi

            if [ -e "$source_dir/acls.txt" ]; then
                original_acl=$(getfacl "$source")
                # Get the desired ACL and set it, then copy while preserving attributes.
                awk -v "file=$source" -f isolate_acl.awk "$source_dir/acls.txt" | setfacl --set-file=- "$source"
                cp -af "$source" "$destination/$new_name"
                # Restore the original ACL of the file
                echo "$original_acl" | setfacl --set-file=- "$source"
            else
                cp -f "$source" "$destination/$new_name"
            fi
        fi
        # Restore SELinux labels
        restorecon -R "$destination" 2> /dev/null
        # Some feedback
        echo "$source -> $destination/$new_name"
    done
fi

# Enable user units
if [ -n "$all_users_units" ]; then
    echo "Enabling systemd user units..."
    # Split username and units using awk
    for i in $(seq $(echo "$all_users_units" | wc -l)); do
        username=$(echo "$all_users_units" | awk -F ':' "NR == $i {print \$1}")
        user_units=$(echo "$all_users_units" | awk -F ':' "NR == $i {print \$2}")

        for user_unit in $user_units; do
            unit_target=$(grep 'WantedBy=' "$user_unit" | cut -f 2 -d =)

            # Default case
            if [ -z "$unit_target" ]; then
                unit_target='default.target'
            fi

            # Manually link units to their target since running systemctl --user from root is relatively hard.
            # machinectl is not always available on the host, neither systemd 248+
            su - "$username" -c "mkdir -p \"\$HOME/.config/systemd/user/$unit_target.wants\"
            ln -s \"\$HOME/.config/systemd/user/$user_unit\" \"\$HOME/.config/systemd/user/$unit_target.wants/$user_unit\""
        done
    done
    echo 'Warning, you need to reload affected users systemd service managers for changes to take effect.'
fi

# Enable system units as requested
# Reload the service manager since units could be newly installed by the package manager
# Far easier than the users one
if [ -n "$system_units" ]; then
    echo "Enabling systemd system units..."
    systemctl daemon-reload
    systemctl enable --now $system_units
fi

# Finally the post script
if [ -n "$post_script" ]; then
    ./"$post_script" "$system_type"
fi
