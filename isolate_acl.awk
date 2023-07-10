#!/usr/bin/awk
index($0, file){
    found = 1
    next
}

found == 1 {
    if ( NF == 0 )
        exit
    print $0
}
