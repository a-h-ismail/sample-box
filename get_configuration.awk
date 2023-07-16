#!/usr/bin/awk
index($0, section) {
    matched = 1
    next
}

matched == 1 {
    # Match any number of whitespaces at the start followed by [something] then any number of whitespaces.
    if ( $0 ~ /^\s*\[.+\]\s*$/ )
        exit
    if ( NF == 0 )
        next
    # Skip comments and empty lines
    else if( $0 ~ /\s*#+.*/ )
        next
    print $0
}
