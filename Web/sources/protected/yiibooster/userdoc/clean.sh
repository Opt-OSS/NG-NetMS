# It will erase all PHP scripts generated by `build.sh`
for path in ./*
do
    dir=`basename $path`
    if [ -d $dir ]
        then rm $dir/$dir.php
    fi
done